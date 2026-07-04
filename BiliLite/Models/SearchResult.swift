import Foundation

/// 搜索结果项
struct BiliSearchResult {
    let videos: [BiliSearchVideoItem]
    let numResults: Int
}

struct BiliSearchVideoItem: Identifiable, Decodable {
    let aid: Int?
    let bvid: String?
    let title: String
    let author: String?
    let mid: Int?
    let pic: String?
    let description: String?
    let duration: String?   // API 返回字符串格式 "5:30"
    let play: Int?
    let danmaku: Int?
    let comment: Int?
    let favorites: Int?
    let pubdate: Int?

    var id: String { bvid ?? "\(aid ?? 0)" }

    var coverURL: URL? {
        guard let p = pic else { return nil }
        return URL(string: p.replacingOccurrences(of: "http://", with: "https://"))
    }
}
