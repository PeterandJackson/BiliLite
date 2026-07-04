import Foundation

/// B站 API 客户端：统一处理请求头、WBI 签名、错误
actor BiliAPIClient {
    static let shared = BiliAPIClient()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 60
        config.httpMaximumConnectionsPerHost = 4
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - 公开方法

    /// GET 不需要 WBI 签名的接口（支持完整 URL 或相对路径）
    func get<T: Decodable>(_ path: String, params: [String: String] = [:], baseURL: String = BiliAPI.baseURL) async throws -> T {
        let url = try buildURL(path, params: params, baseURL: baseURL)
        var req = URLRequest(url: url)
        injectHeaders(&req, forPassport: baseURL.contains("passport"))
        return try await executeWithRetry(req)
    }

    /// GET 需要 WBI 签名的接口
    func getWBI<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> T {
        try await getWBIImpl(path, params: params, allowRetry: true)
    }

    /// WBI GET 的内部实现：allowRetry=true 时，-412 会刷新密钥并用原始 params 重新签名重试
    private func getWBIImpl<T: Decodable>(_ path: String, params: [String: String], allowRetry: Bool) async throws -> T {
        let signed = try await WBISigner.shared.sign(params)
        let url = try buildURL(path, params: signed)
        var req = URLRequest(url: url)
        injectHeaders(&req)

        let (data, resp) = try await session.data(for: req)

        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            throw BiliError.httpError(http.statusCode)
        }

        do {
            let response = try decoder.decode(BiliResponse<T>.self, from: data)
            if response.code == 0, let d = response.data {
                return d
            }
            if response.code == -412, allowRetry {
                // 刷新密钥，用原始 params 重新签名，彻底重建 URL
                try await WBISigner.shared.refreshKeys()
                return try await getWBIImpl(path, params: params, allowRetry: false)
            }
            if response.code == -799 || response.code == -509 {
                throw BiliError.rateLimited
            }
            throw BiliError.apiError(code: response.code, message: response.message)
        } catch let e as BiliError {
            throw e
        } catch {
            // Decoding 失败，尝试直接解析原始 T
        }

        // 如果 BiliResponse 解析失败，尝试直接解析为 T
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BiliError.decodeFailed
        }
    }

    /// POST 请求（用于登录等）
    func post<T: Decodable>(_ path: String, params: [String: String] = [:], baseURL: String = BiliAPI.baseURL) async throws -> T {
        let url = try buildURL(path, params: [:], baseURL: baseURL)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        injectHeaders(&req, forPassport: baseURL.contains("passport"))
        // 构造 body
        var comps = URLComponents(); comps.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        req.httpBody = comps.query?.data(using: .utf8)
        return try await executeWithRetry(req)
    }

    /// 直接获取原始 Data（用于图片下载等）
    func getData(_ url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(BiliAPI.userAgent, forHTTPHeaderField: "User-Agent")
        // B站 CDN 必须带 Referer，其他域名不需要
        if url.host?.contains("bilibili.com") == true {
            req.setValue(BiliAPI.referer, forHTTPHeaderField: "Referer")
        }

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            throw BiliError.httpError(http.statusCode)
        }
        return data
    }

    // MARK: - 内部方法

    private func buildURL(_ path: String, params: [String: String], baseURL: String = BiliAPI.baseURL) throws -> URL {
        let base = path.hasPrefix("http") ? "" : baseURL
        var components = URLComponents(string: "\(base)\(path)")
        if !params.isEmpty {
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else {
            throw BiliError.invalidURL
        }
        return url
    }

    private func injectHeaders(_ req: inout URLRequest, forPassport: Bool = false) {
        req.setValue(BiliAPI.userAgent, forHTTPHeaderField: "User-Agent")
        if !forPassport { req.setValue(BiliAPI.referer, forHTTPHeaderField: "Referer") }
        var cookie = DeviceIdentity.shared.getCookieSync()
        // Inject saved SESSDATA (login session) from Keychain — encrypted at rest
        if let sessdata = KeychainHelper.read(key: "bili_sessdata"), !sessdata.isEmpty {
            cookie += "; SESSDATA=\(sessdata)"
        }
        if !cookie.isEmpty { req.setValue(cookie, forHTTPHeaderField: "Cookie") }
    }

    /// 执行请求，解析 BiliResponse 并处理通用错误码
    private func executeWithRetry<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, resp) = try await session.data(for: req)

        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            throw BiliError.httpError(http.statusCode)
        }

        // 先尝试解析为 BiliResponse
        do {
            let response = try decoder.decode(BiliResponse<T>.self, from: data)
            if response.code == 0, let d = response.data {
                return d
            }
            if response.code == -799 || response.code == -509 {
                throw BiliError.rateLimited
            }
            throw BiliError.apiError(code: response.code, message: response.message)
        } catch let e as BiliError {
            throw e
        } catch {
            // Decoding 失败，尝试直接解析原始 T
        }

        // 如果 BiliResponse 解析失败，尝试直接解析为 T（用于非标准响应格式）
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BiliError.decodeFailed
        }
    }
}
