import Foundation

/// 评论
struct Comment: Identifiable, Decodable {
    let rpid: Int
    let oid: Int
    let mid: Int
    let root: Int
    let parent: Int
    let count: Int          // 子回复数
    let rcount: Int
    let ctime: Int
    let like: Int
    let member: CommentUser
    let content: CommentContent
    let replies: [Comment]? // 嵌套回复（最多3条）

    var id: Int { rpid }
    var isSubReply: Bool { root != 0 }
}

struct CommentUser: Decodable {
    let mid: String         // B站 API 返回字符串
    let uname: String
    let avatar: String
    let levelInfo: CommentLevelInfo?

    var avatarURL: URL? {
        URL(string: avatar.replacingOccurrences(of: "http://", with: "https://"))
    }

    struct CommentLevelInfo: Decodable {
        let currentLevel: Int?
    }
}

struct CommentContent: Decodable {
    let message: String
}

/// 评论主题（用于 CommentListView）
struct ReplyPage: Decodable {
    let num: Int?
    let size: Int?
    let count: Int?
    let acount: Int?
}

struct ReplyData: Decodable {
    let page: ReplyPage?
    let replies: [Comment]?
    let top: Comment?
    let upper: ReplyUpper?
}

struct ReplyUpper: Decodable {
    let mid: Int?
    let name: String?
}
