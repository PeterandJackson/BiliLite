import Foundation

/// UP主 / 用户详细信息
struct UserProfile: Decodable {
    let mid: Int
    let name: String
    let sex: String?
    let face: String?
    let sign: String?
    let level: Int?
    let birthday: String?
    let vip: UserVip?
    let official: UserOfficial?
    let liveRoom: UserLiveRoom?

    var faceURL: URL? {
        guard let f = face else { return nil }
        return URL(string: f.replacingOccurrences(of: "http://", with: "https://"))
    }

    struct UserVip: Decodable {
        let type: Int?
        let status: Int?
    }

    struct UserOfficial: Decodable {
        let role: Int?
        let title: String?
    }

    struct UserLiveRoom: Decodable {
        let roomStatus: Int?
        let liveStatus: Int?
        let roomid: Int?
    }
}
