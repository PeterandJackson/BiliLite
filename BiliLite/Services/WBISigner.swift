import Foundation
import CryptoKit

/// WBI 签名器：自动获取/缓存密钥，为请求参数生成 w_rid + wts
actor WBISigner {
    static let shared = WBISigner()

    private var mixinKey: String?
    private var lastFetch: Date?
    private let cacheTTL: TimeInterval = 12 * 3600 // 12小时

    /// 固定 shuffle 表 — 从 64 字符 rawKey 中取前 32 个
    private let mixinKeyEncTab: [Int] = [
        46, 47, 18,  2, 53,  8, 23, 32,
        15, 50, 10, 31, 58,  3, 45, 35,
        27, 43,  5, 49, 33,  9, 42, 19,
        29, 28, 14, 39, 12, 38, 41, 13,
        37, 48,  7, 16, 24, 55, 40, 61,
        26, 17,  0,  1, 60, 51, 30,  4,
        22, 25, 54, 21, 56, 59,  6, 63,
        57, 62, 11, 36, 20, 34, 44, 52
    ]

    // MARK: - 获取密钥

    private func ensureKeys() async throws {
        // 缓存未过期
        if let last = lastFetch, Date().timeIntervalSince(last) < cacheTTL, mixinKey != nil {
            return
        }

        try await fetchKeys()
    }

    private func fetchKeys() async throws {
        let url = URL(string: "\(BiliAPI.baseURL)\(BiliAPI.nav)")!
        var req = URLRequest(url: url)
        req.setValue(BiliAPI.userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue(BiliAPI.referer, forHTTPHeaderField: "Referer")
        req.setValue(await DeviceIdentity.shared.getCookieString(), forHTTPHeaderField: "Cookie")

        let (data, resp) = try await URLSession.shared.data(for: req)

        if let httpResp = resp as? HTTPURLResponse, httpResp.statusCode != 200 {
            throw BiliError.httpError(httpResp.statusCode)
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(NavResponse.self, from: data)

        let imgURL = response.data.wbi_img.img_url
        let subURL = response.data.wbi_img.sub_url

        guard
            let imgFile = imgURL.split(separator: "/").last?.split(separator: ".").first,
            let subFile = subURL.split(separator: "/").last?.split(separator: ".").first
        else {
            throw BiliError.wbiKeyExtractionFailed
        }

        let rawKey = String(imgFile) + String(subFile)
        var chars = [Character](repeating: "\0", count: 32)
        for (i, idx) in mixinKeyEncTab.enumerated() where i < 32 {
            chars[i] = rawKey[rawKey.index(rawKey.startIndex, offsetBy: idx)]
        }

        self.mixinKey = String(chars)
        self.lastFetch = Date()
    }

    // MARK: - 签名

    /// 强制刷新密钥（用于 -412 重试）
    func refreshKeys() async throws {
        mixinKey = nil
        lastFetch = nil
        try await fetchKeys()
    }

    /// 对参数字典签名，返回包含 w_rid + wts 的新字典
    func sign(_ params: [String: String]) async throws -> [String: String] {
        try await ensureKeys()

        guard let key = mixinKey else {
            throw BiliError.wbiKeyNotAvailable
        }

        var signed = params
        let wts = String(Int(Date().timeIntervalSince1970))
        signed["wts"] = wts

        // 按 key 排序 → 编码 → 拼接
        let sortedKeys = signed.keys.sorted()
        let query = sortedKeys.map { k in
            let v = signed[k] ?? ""
            return "\(k)=\(wbiEncode(v))"
        }.joined(separator: "&")

        // MD5(query + mixin_key)
        let wrid = (query + key).md5()
        signed["w_rid"] = wrid

        return signed
    }

    // MARK: - WBI 编码

    /// WBI 参数编码：过滤 !'()* → URL 编码（大写十六进制，空格为 %20）
    private func wbiEncode(_ raw: String) -> String {
        let filtered = raw.filter { !"!'()*".contains($0) }
        var result = ""
        for ch in filtered.utf8 {
            let scalar = UnicodeScalar(ch)
            if CharacterSet.alphanumerics.contains(scalar)
                || CharacterSet(charactersIn: "-_.~").contains(scalar) {
                result.append(Character(scalar))
            } else if ch == 0x20 {
                result.append("%20")
            } else {
                result.append(String(format: "%%%02X", ch))
            }
        }
        return result
    }
}

// MARK: - 内部模型

private struct NavResponse: Decodable {
    struct Inner: Decodable {
        struct Img: Decodable {
            let img_url: String
            let sub_url: String
        }
        let wbi_img: Img
    }
    let data: Inner
}

// MARK: - MD5 扩展

extension String {
    func md5() -> String {
        Insecure.MD5.hash(data: Data(self.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
