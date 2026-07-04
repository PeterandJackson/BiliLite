import SwiftUI

// MARK: - 统一登录 ViewModel（QR / 密码 / 短信）

@MainActor
final class LoginViewModel: ObservableObject {
    enum LoginMethod: CaseIterable { case qr, password, sms }
    @Published var method: LoginMethod = .qr
    @Published var loginStatus = ""
    @Published var isLoggedIn = false
    @Published var userName = ""
    @Published var userFace = ""

    // QR
    @Published var qrCodeImage: UIImage?
    private var pollTask: Task<Void, Never>?
    private var qrKey = ""
    // 密码
    @Published var phoneOrUser = ""
    @Published var password = ""
    @Published var captchaImage: UIImage?
    @Published var captchaKey = ""
    // 短信
    @Published var smsPhone = ""
    @Published var smsCode = ""
    @Published var smsSent = false
    @Published var smsCountdown = 0
    private var smsCountryCode = "+86"
    private var smsCaptchaKey = ""

    let captchaBase = "https://passport.bilibili.com"

    // MARK: - QR
    func fetchQRCode() async {
        loginStatus = "正在生成二维码..."
        do {
            let qr: QRGenResp = try await BiliAPIClient.shared.get("/x/passport-login/web/qrcode/generate", params: [:], baseURL: "https://passport.bilibili.com")
            guard qr.code == 0, let u = URL(string: qr.data.url) else { loginStatus = "QR生成失败"; return }
            qrKey = qr.data.qrcode_key; loginStatus = "请用B站App扫描"
            generateQRImage(from: qr.data.url)
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
                    switch p.data.code {
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

    // MARK: - 密码登录
    func passwordLogin() async {
        loginStatus = "正在登录..."
        do {
            // 1. 获取 captcha（如果需要）
            var params: [String: String] = [
                "username": phoneOrUser, "password": password,
                "source": "main_web", "token": "", "go_url": "https://www.bilibili.com",
            ]
            if !captchaKey.isEmpty { params["captcha"] = captchaKey }
            let resp: LoginResp = try await BiliAPIClient.shared.post("/x/passport-login/oauth2/login", params: params, baseURL: "https://passport.bilibili.com")
            if resp.code == 0 {
                if let cookie = resp.data?.token_info?.cookie {
                    saveCookie(cookie)
                }
                loginSuccess()
            } else if resp.code == -105 {
                loginStatus = "需要验证码"; await refreshCaptcha()
            } else {
                loginStatus = resp.message ?? "密码错误"
            }
        } catch { loginStatus = error.localizedDescription }
    }

    func refreshCaptcha() async {
        do {
            let r: CaptchaResp = try await BiliAPIClient.shared.get("/x/passport-captcha/captcha", params: ["source": "main_web"], baseURL: "https://passport.bilibili.com")
            captchaKey = r.data?.geetest?.gt ?? ""
            if let imgURL = r.data?.geetest?.challenge {
                // 极验验证码用 webview 更合适，这里做简化
                loginStatus = "不支持极验验证码，请用短信登录"
            }
        } catch {}
    }

    // MARK: - 短信登录
    var smsReady: Bool { smsPhone.count >= 11 && smsCountdown == 0 }

    func sendSMS() async {
        loginStatus = "发送验证码..."
        do {
            let r: SMSResp = try await BiliAPIClient.shared.post("/x/passport-login/sms/send", params: ["cid": smsCountryCode, "tel": smsPhone, "source": "main_web", "token": smsCaptchaKey], baseURL: "https://passport.bilibili.com")
            if r.code == 0 {
                smsSent = true; smsCaptchaKey = r.data.captcha_key
                smsCountdown = 60; loginStatus = "验证码已发送"
                Task { @MainActor in
                    while smsCountdown > 0 { try? await Task.sleep(nanoseconds: 1_000_000_000); smsCountdown -= 1 }
                }
            } else { loginStatus = r.message ?? "发送失败" }
        } catch { loginStatus = error.localizedDescription }
    }

    func smsLogin() async {
        loginStatus = "登录中..."
        do {
            let r: LoginResp = try await BiliAPIClient.shared.post("/x/passport-login/sms/login", params: ["captcha_key": smsCaptchaKey, "code": smsCode, "cid": smsCountryCode, "tel": smsPhone, "source": "main_web"], baseURL: "https://passport.bilibili.com")
            if r.code == 0 {
                if let c = r.data?.token_info?.cookie { saveCookie(c) }
                loginSuccess()
            } else { loginStatus = r.message ?? "验证码错误" }
        } catch { loginStatus = error.localizedDescription }
    }

    // MARK: - 通用
    private func saveCookie(_ raw: String) {
        // 提取 SESSDATA
        for part in raw.split(separator: ";") {
            let kv = part.trimmingCharacters(in: .whitespaces)
            if kv.hasPrefix("SESSDATA=") {
                UserDefaults.standard.set(String(kv.dropFirst(9)), forKey: "bili_sessdata")
            }
            if kv.hasPrefix("DedeUserID=") {
                UserDefaults.standard.set(String(kv.dropFirst(11)), forKey: "bili_uid")
            }
            if kv.hasPrefix("bili_jct=") {
                UserDefaults.standard.set(String(kv.dropFirst(9)), forKey: "bili_jct")
            }
        }
    }

    private func loginSuccess() {
        loginStatus = "登录成功！"; isLoggedIn = true; pollTask?.cancel()
        Task { await fetchUserInfo() }
    }

    private func fetchUserInfo() async {
        do {
            let nav: LoginNavResp = try await BiliAPIClient.shared.get(BiliAPI.nav)
            userName = nav.data.uname ?? "用户"
            userFace = nav.data.face ?? ""
        } catch {}
    }

    func cancel() { pollTask?.cancel(); pollTask = nil }
}

// MARK: - 内部模型

private struct QRGenResp: Decodable { let code: Int; let data: QRGenData; struct QRGenData: Decodable { let url: String; let qrcode_key: String } }
private struct QRCheckResp: Decodable { let data: QRCheckData; struct QRCheckData: Decodable { let code: Int; let message: String? } }
private struct LoginResp: Decodable { let code: Int; let message: String?; let data: LoginData?; struct LoginData: Decodable { let token_info: TokenInfo?; struct TokenInfo: Decodable { let cookie: String? } } }
private struct CaptchaResp: Decodable { let data: CaptchaData?; struct CaptchaData: Decodable { let geetest: GeeTest?; struct GeeTest: Decodable { let gt: String; let challenge: String } } }
private struct SMSResp: Decodable { let code: Int; let message: String?; let data: SMSData; struct SMSData: Decodable { let captcha_key: String } }
private struct LoginNavResp: Decodable { let data: LoginNavData; struct LoginNavData: Decodable { let uname: String?; let face: String? } }
