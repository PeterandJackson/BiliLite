import Foundation

/// B站 API 常量
enum BiliAPI {
    static let baseURL = "https://api.bilibili.com"
    static let referer = "https://www.bilibili.com"
    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1"

    /// 首页热门视频（无需签名）
    static let popular = "/x/web-interface/popular"
    /// 个性化推荐（WBI签名）
    static let recommend = "/x/web-interface/wbi/index/top/feed/rcmd"
    /// 热搜榜
    static let hotSearch = "/x/web-interface/wbi/search/square"
    /// WBI密钥获取
    static let nav = "/x/web-interface/nav"
    /// 视频详情 (WBI)
    static let videoInfo = "/x/web-interface/wbi/view"
    /// 播放流 (WBI)
    static let playURL = "/x/player/wbi/playurl"
    /// 搜索 (WBI)
    static let search = "/x/web-interface/wbi/search/type"
    /// 评论 (WBI)
    static let replyMain = "/x/v2/reply/wbi/main"
    /// 子回复
    static let replySub = "/x/v2/reply/reply"
    /// 用户信息 (WBI)
    static let userInfo = "/x/space/wbi/acc/info"
    /// 相关视频
    static let related = "/x/web-interface/archive/related"
}

/// 视频画质代码
enum BiliQuality: Int, CaseIterable {
    case p360  = 16
    case p480  = 32
    case p720  = 64
    case p1080 = 80

    var label: String {
        switch self {
        case .p360:  return "360P"
        case .p480:  return "480P"
        case .p720:  return "720P"
        case .p1080: return "1080P"
        }
    }
}

/// 自定义错误
enum BiliError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case apiError(code: Int, message: String)
    case wbiKeyExtractionFailed
    case wbiKeyNotAvailable
    case noData
    case decodeFailed
    case missingCID
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidURL:             return "无效链接"
        case .httpError(let code):    return "网络错误 (\(code))"
        case .apiError(let c, let m): return "\(m) (\(c))"
        case .wbiKeyExtractionFailed: return "密钥提取失败"
        case .wbiKeyNotAvailable:     return "签名密钥未就绪"
        case .noData:                 return "无数据"
        case .decodeFailed:           return "数据解析失败"
        case .missingCID:             return "缺少视频分P信息"
        case .rateLimited:            return "请求过于频繁，请稍后"
        }
    }
}
