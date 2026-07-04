import SwiftUI
import WebKit

extension Notification.Name {
    static let biliLoginSuccess = Notification.Name("biliLoginSuccess")
    static let biliFavoritesChanged = Notification.Name("biliFavoritesChanged")
    static let biliHistoryChanged = Notification.Name("biliHistoryChanged")
}

// MARK: - 统一登录 ViewModel（QR / 网页登录）

@MainActor
final class LoginViewModel: ObservableObject {
    enum LoginMethod: CaseIterable { case qr, web }
    @Published var method: LoginMethod = .qr
    @Published var loginStatus = ""
    @Published var isLoggedIn = false
    @Published var userName = ""
    @Published var userFace = ""

    // QR
    @Published var qrCodeImage: UIImage?
    private var pollTask: Task<Void, Never>?
    private var qrKey = ""

    // Web 登录
    weak var webView: WKWebView?
    @Published var navigatedAwayFromPassport = false

    // MARK: - QR
    func fetchQRCode() async {
        loginStatus = "正在生成二维码..."
        do {
            let qr: QRGenResp = try await BiliAPIClient.shared.get("/x/passport-login/web/qrcode/generate", params: [:], baseURL: "https://passport.bilibili.com")
            guard let u = URL(string: qr.url) else { loginStatus = "QR生成失败"; return }
            qrKey = qr.qrcodeKey; loginStatus = "请用B站App扫描"
            generateQRImage(from: qr.url)
            startQRPoll()
        } catch { loginStatus = error.localizedDescription }
    }

    private func generateQRImage(from s: String) {
        guard let d = s.data(using: .utf8), let f = CIFilter(name: "CIQRCodeGenerator") else { return }
        f.setValue(d, forKey: "inputMessage"); f.setValue("H", forKey: "inputCorrectionLevel")
        guard let ci = f.outputImage else { return }
        let t = CGAffineTransform(scaleX: 10, y: 10)
        if let cg = CIContext().createCGImage(ci.transformed(by: t), from: ci.transformed(by: t).extent) { qrCodeImage = UIImage(cgImage: cg) }
    }

    private func startQRPoll() {
        pollTask?.cancel()
        pollTask = Task { @MainActor in
            for _ in 0..<120 {
                if Task.isCancelled { return }
                do {
                    let p: QRCheckResp = try await BiliAPIClient.shared.get("/x/passport-login/web/qrcode/poll", params: ["qrcode_key": qrKey], baseURL: "https://passport.bilibili.com")
                    switch p.code {
                    case 0: loginSuccess()
                    case 86038: loginStatus = "二维码已过期"; return
                    case 86090: loginStatus = "已扫码，请确认"
                    case 86101: loginStatus = "请在手机确认"
                    default: break
                    }
                } catch { if !Task.isCancelled { loginStatus = "轮询出错" } }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            loginStatus = "超时"
        }
    }

    // MARK: - Web 登录：从 WKWebView 提取 Cookie

    func extractCookiesFromWebView(onComplete: @escaping (Bool) -> Void) {
        guard webView != nil else {
            loginStatus = "WebView 未初始化"
            onComplete(false)
            return
        }

        loginStatus = "正在读取登录信息..."

        let cookieStore = WKWebsiteDataStore.default().httpCookieStore

        cookieStore.getAllCookies { cookies in
            var foundSESSDATA = false

            for cookie in cookies {
                guard cookie.domain.contains("bilibili.com") else { continue }

                switch cookie.name {
                case "SESSDATA":
                    KeychainHelper.save(key: "bili_sessdata", value: cookie.value)
                    foundSESSDATA = true
                case "DedeUserID":
                    KeychainHelper.save(key: "bili_uid", value: cookie.value)
                case "bili_jct":
                    KeychainHelper.save(key: "bili_jct", value: cookie.value)
                default:
                    break
                }
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if foundSESSDATA {
                    self.loginSuccess()
                    onComplete(true)
                } else {
                    self.loginStatus = "未检测到登录信息，请确认已在网页中完成登录"
                    onComplete(false)
                }
            }
        }
    }

    // MARK: - 通用
    private func loginSuccess() {
        loginStatus = "登录成功！"; isLoggedIn = true; pollTask?.cancel()
        NotificationCenter.default.post(name: .biliLoginSuccess, object: nil)
        Task { await fetchUserInfo() }
    }

    private func fetchUserInfo() async {
        do {
            let nav: LoginNavResp = try await BiliAPIClient.shared.get(BiliAPI.nav)
            userName = nav.uname ?? "用户"
            userFace = nav.face ?? ""
        } catch {}
    }

    func cancel() { pollTask?.cancel(); pollTask = nil }
}

// MARK: - 内部模型

private struct QRGenResp: Decodable { let url: String; let qrcodeKey: String }
private struct QRCheckResp: Decodable { let code: Int; let message: String? }
private struct LoginNavResp: Decodable {
    let isLogin: Int?
    let uname: String?
    let face: String?

    enum CodingKeys: String, CodingKey { case isLogin, uname, face }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uname = try container.decodeIfPresent(String.self, forKey: .uname)
        face = try container.decodeIfPresent(String.self, forKey: .face)
        // B站 nav API 可能返回 isLogin 为 Bool 或 Int，兼容两种
        if let intVal = try? container.decodeIfPresent(Int.self, forKey: .isLogin) {
            isLogin = intVal
        } else if let boolVal = try? container.decodeIfPresent(Bool.self, forKey: .isLogin) {
            isLogin = boolVal ? 1 : 0
        } else {
            isLogin = nil
        }
    }
}
