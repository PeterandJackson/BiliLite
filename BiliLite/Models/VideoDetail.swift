import Foundation

/// 视频详情（/wbi/view 返回的核心数据）
struct VideoDetail: Decodable {
    let bvid: String
    let aid: Int
    let title: String
    let pic: String
    let duration: Int
    let owner: VideoOwner
    let stat: VideoStat
    let desc: String?
    let pubdate: Int
    let ctime: Int
    let cid: Int?           // 默认分P的 cid
    let pages: [VideoPage]?
    let tname: String?      // 分区名称
    let dynamic: String?    // 动态文本

    /// 当前播放的 cid
    var currentCID: Int {
        cid ?? pages?.first?.cid ?? 0
    }

    var descStripped: String {
        desc ?? dynamic ?? ""
    }

    var coverURL: URL? {
        URL(string: pic.replacingOccurrences(of: "http://", with: "https://"))
    }
}

/// 分P
struct VideoPage: Identifiable, Decodable {
    let cid: Int
    let page: Int
    let part: String
    let duration: Int

    var id: Int { cid }
}
