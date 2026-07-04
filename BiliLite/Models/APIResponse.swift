import Foundation

/// B站 API 统一响应壳
/// 大部分接口: { "code": 0, "message": "0", "data": {...} }
struct BiliResponse<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: T?

    var isSuccess: Bool { code == 0 }
}

/// 列表类响应（data 内嵌 list / item / replies 等）
struct BiliListWrapper<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: BiliListData<T>?

    struct BiliListData<T: Decodable>: Decodable {
        let list: T?
        let item: T?
        let replies: T?
        let result: T?
        let archives: T?
        let page: BiliPage?

        struct BiliPage: Decodable {
            let num: Int?
            let size: Int?
            let count: Int?
            let acount: Int?
        }
    }

    var items: T? {
        data?.list ?? data?.item ?? data?.replies ?? data?.result ?? data?.archives
    }
}

/// 热门视频响应（data 内有 list + no_more）
struct PopularResponse: Decodable {
    let list: [Video]
    let noMore: Bool?
}

/// 搜索响应（result 是混合类型的数组）
struct BiliSearchResponse: Decodable {
    let code: Int
    let message: String
    let data: BiliSearchData?
}

struct BiliSearchData: Decodable {
    let numResults: Int?
    let result: [BiliSearchBlock]?
}

struct BiliSearchBlock: Decodable {
    let resultType: String?
    let data: [BiliSearchVideoItem]?
}

/// 写操作通用响应（点赞/投币/收藏等）
struct BiliActionResp: Decodable {
    let code: Int
    let message: String
}

/// 关注状态查询响应
struct RelationResp: Decodable {
    let attribute: Int?   // 1=已关注 2=未关注 6=已互粉
}

/// 动态流响应
struct DynamicFeedResp: Decodable {
    let items: [DynamicItem]?
    let hasMore: Bool?
    let offset: String?
}

struct DynamicItem: Identifiable, Decodable {
    let idStr: String?
    var id: String { idStr ?? UUID().uuidString }
    let type: String?
    let modules: DynamicModules?

    struct DynamicModules: Decodable {
        let moduleAuthor: AuthorModule?
        let moduleDynamic: DescModule?

        struct AuthorModule: Decodable {
            let mid: Int?
            let name: String?
            let face: String?
            let pubAction: String?   // "投稿了视频" / "转发动态"
            let pubTime: String?     // "x小时前"
        }
        struct DescModule: Decodable {
            let desc: DescText?
            let major: MajorModule?
            struct DescText: Decodable { let text: String? }
            struct MajorModule: Decodable {
                let archive: DynamicArchive?
                let type: String?
                struct DynamicArchive: Decodable {
                    let aid: String?
                    let bvid: String?
                    let title: String?
                    let cover: String?
                    let durationText: String?
                    let play: Int?
                    let danmaku: Int?
                }
            }
        }
    }
}

/// 番剧时间表响应
struct BangumiTimelineResp: Decodable {
    let result: [BangumiDay]?
    struct BangumiDay: Decodable {
        let date: String?
        let dayOfWeek: Int?
        let seasons: [BangumiSeason]?
    }
}

struct BangumiSeason: Identifiable, Decodable {
    let seasonId: Int?
    let title: String?
    let cover: String?
    let url: String?
    let pubIndex: String?
    var id: Int { seasonId ?? 0 }
}
