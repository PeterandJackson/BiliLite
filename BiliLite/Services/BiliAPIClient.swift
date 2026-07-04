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

    /// GET 不需要 WBI 签名的接口
    func get<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> T {
        let url = try buildURL(path, params: params)
        var req = URLRequest(url: url)
        injectHeaders(&req)
        return try await executeWithRetry(req)
    }

    /// GET 需要 WBI 签名的接口
    func getWBI<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> T {
        let signed = try await WBISigner.shared.sign(params)
        let url = try buildURL(path, params: signed)
        var req = URLRequest(url: url)
        injectHeaders(&req)
        return try await executeWithRetry(req, allowRetry: true)
    }

    /// 解析带 BiliListWrapper 的列表接口
    func getWBIList<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> [T] {
        let signed = try await WBISigner.shared.sign(params)
        let url = try buildURL(path, params: signed)
        var req = URLRequest(url: url)
        injectHeaders(&req)

        let wrapper: BiliListWrapper<T> = try await executeWithRetry(req, allowRetry: true)
        if let items = wrapper.items {
            return items
        }
        return []
    }

    /// 直接获取原始 Data（用于图片下载等）
    func getData(_ url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(BiliAPI.referer, forHTTPHeaderField: "Referer")
        req.setValue(BiliAPI.userAgent, forHTTPHeaderField: "User-Agent")
        // 视频 CDN 必须带 Referer
        if !url.host?.contains("bilibili.com") ?? true {
            req.setValue(BiliAPI.referer, forHTTPHeaderField: "Referer")
        }

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            throw BiliError.httpError(http.statusCode)
        }
        return data
    }

    // MARK: - 内部方法

    private func buildURL(_ path: String, params: [String: String]) throws -> URL {
        var components = URLComponents(string: "\(BiliAPI.baseURL)\(path)")
        if !params.isEmpty {
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else {
            throw BiliError.invalidURL
        }
        return url
    }

    private func injectHeaders(_ req: inout URLRequest) {
        req.setValue(BiliAPI.userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue(BiliAPI.referer, forHTTPHeaderField: "Referer")
        let cookie = DeviceIdentity.shared.getCookieSync()
        if !cookie.isEmpty {
            req.setValue(cookie, forHTTPHeaderField: "Cookie")
        }
    }

    /// 执行请求，可选 -412 重试
    private func executeWithRetry<T: Decodable>(_ req: URLRequest, allowRetry: Bool = false) async throws -> T {
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
            if response.code == -412, allowRetry {
                // 刷新密钥后重试一次
                try await WBISigner.shared.refreshKeys()
                var retryReq = req
                injectHeaders(&retryReq)
                return try await executeWithRetry(retryReq, allowRetry: false)
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
