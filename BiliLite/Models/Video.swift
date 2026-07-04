import Foundation

/// 视频列表项（热门列表中的视频）
struct Video: Identifiable, Decodable {
    let aid: Int
    let bvid: String
    let title: String
    let pic: String          // 封面图 URL
    let duration: Int        // 秒
    let owner: VideoOwner
    let stat: VideoStat
    let pubdate: Int
    let desc: String?
    let cid: Int?

    var id: Int { aid }

    /// 高分辨率封面 (http → https)
    var coverURL: URL? {
        let https = pic.replacingOccurrences(of: "http://", with: "https://")
        return URL(string: https)
    }
}

/// UP主简要信息
struct VideoOwner: Decodable {
    let mid: Int
    let name: String
    let face: String

    var faceURL: URL? {
        URL(string: face.replacingOccurrences(of: "http://", with: "https://"))
    }
}

/// 视频统计数据
struct VideoStat: Decodable {
    let view: Int
    let danmaku: Int
    let reply: Int
    let favorite: Int
    let like: Int
    let coin: Int
    let share: Int
}
