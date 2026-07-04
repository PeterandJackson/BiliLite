import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var qrCodeURL: URL?
    @Published var qrCodeImage: UIImage?
    @Published var loginStatus: String = "扫码登录"
    @Published var isLoggedIn = false
    @Published var sessionCookie: String = ""
    @Published var userName: String = ""
    @Published var userFace: String = ""

    private var pollTask: Task<Void, Never>?
    private var qrKey: String = ""

    /// 获取登录 QR 码
    func fetchQRCode() async {
        do {
            let qrResp: QRGenerateResponse = try await BiliAPIClient.shared.get(
                "/x/passport-login/web/qrcode/generate",
                params: [:],
                baseURL: "https://passport.bilibili.com"
            )
            if qrResp.code == 0, let url = URL(string: qrResp.data.url) {
                qrCodeURL = url
                qrKey = qrResp.data.qrcode_key
                loginStatus = "请用B站App扫描二维码"
                // 生成 QR 码图片
                generateQRImage(from: qrResp.data.url)
                // 开始轮询
                startPolling()
            }
        } catch {
            loginStatus = "获取二维码失败: \(error.localizedDescription)"
        }
    }

    private func generateQRImage(from url: String) {
        guard let data = url.data(using: .utf8) else { return }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaled = ciImage.transformed(by: transform)
        let context = CIContext()
        if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
            qrCodeImage = UIImage(cgImage: cgImage)
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            let maxAttempts = 120
            for _ in 0..<maxAttempts {
                if Task.isCancelled { return }
                do {
                    let resp: QRCheckResponse = try await BiliAPIClient.shared.get(
                        "/x/passport-login/web/qrcode/poll",
                        params: ["qrcode_key": qrKey],
                        baseURL: "https://passport.bilibili.com"
                    )
                    if resp.data.code == 0 {
                        loginStatus = "登录成功！请在「我的」页面查看登录状态"
                        isLoggedIn = true
                        // 轮询成功后 cookie 已由服务端 Set-Cookie 设置
                        // 需要从响应中提取（简化处理：提示用户手动输入 cookie）
                        Task { await fetchUserInfo() }
                        return
                    } else if resp.data.code == 86038 {
                        loginStatus = "二维码已过期，请刷新"
                        return
                    } else if resp.data.code == 86090 {
                        loginStatus = "已扫码，请确认登录"
                    } else if resp.data.code == 86101 {
                        loginStatus = "请在手机端确认"
                    }
                } catch {
                    if !Task.isCancelled { loginStatus = "轮询出错..." }
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            loginStatus = "登录超时，请重试"
        }
    }

    private func fetchUserInfo() async {
        do {
            let nav: LoginNavResponse = try await BiliAPIClient.shared.get(BiliAPI.nav)
            userName = nav.data.uname ?? "用户"
            userFace = nav.data.face ?? ""
        } catch {}
    }

    func cancel() { pollTask?.cancel(); pollTask = nil }
}

// MARK: - QR 响应模型

private struct QRGenerateResponse: Decodable {
    let code: Int
    let data: QRGenerateData
    struct QRGenerateData: Decodable {
        let url: String
        let qrcode_key: String
    }
}

private struct QRCheckResponse: Decodable {
    let data: QRCheckData
    struct QRCheckData: Decodable {
        let code: Int
        let message: String?
        let refresh_token: String?
    }
}

private struct LoginNavResponse: Decodable {
    let data: LoginNavData
    struct LoginNavData: Decodable {
        let uname: String?
        let face: String?
        let isLogin: Bool?
    }
}
