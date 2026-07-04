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
    let result_type: String?
    let data: [BiliSearchVideoItem]?
}
