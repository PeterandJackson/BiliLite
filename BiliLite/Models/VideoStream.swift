import Foundation

/// 视频播放流（/wbi/playurl 返回，fnval=1 MP4 模式）
struct VideoStream: Decodable {
    let quality: Int
    let format: String?
    let timelength: Int
    let acceptQuality: [Int]?
    let durl: [StreamURL]?

    /// 第一个可播放的 URL
    var firstURL: URL? {
        guard let urlStr = durl?.first?.url else { return nil }
        let https = urlStr.replacingOccurrences(of: "http://", with: "https://")
        return URL(string: https)
    }

    /// 备用 URL 列表
    var allURLs: [URL] {
        durl?.compactMap { item in
            item.backupUrl?.compactMap { URL(string: $0.replacingOccurrences(of: "http://", with: "https://")) } ?? []
        }.flatMap { $0 } ?? []
    }
}

struct StreamURL: Decodable {
    let url: String
    let backupUrl: [String]?
    let size: Int?
    let length: Int?
}
