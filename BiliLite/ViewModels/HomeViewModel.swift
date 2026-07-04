import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var seenIDs = Set<String>()
    private var currentPage = 1
    private var hasMore = true

    func loadPopular() async {
        guard !isLoading else { return }
        isLoading = true; errorMessage = nil
        do {
            let resp: PopularResponse = try await BiliAPIClient.shared.get(BiliAPI.popular, params: ["pn": "\(currentPage)", "ps": "20"])
            let fresh = resp.list.filter { seenIDs.insert($0.bvid).inserted }
            if currentPage == 1 { videos = fresh } else { videos.append(contentsOf: fresh) }
            hasMore = resp.list.count >= 20 && !(resp.noMore ?? false)
            currentPage += 1
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    /// 推荐接口
    func loadRecommend() async {
        guard !isLoading else { return }
        isLoading = true; errorMessage = nil
        do {
            let resp: RecommendResp = try await BiliAPIClient.shared.getWBI(BiliAPI.recommend, params: ["ps": "20", "fresh_idx": "\(currentPage)", "fresh_idx_1h": "\(Int.random(in: 1...5))", "fresh_type": "4", "web_location": "1430650"])
            let list = resp.item ?? []
            let fresh = list.filter { seenIDs.insert($0.bvid).inserted }
            if currentPage == 1 { videos = fresh } else { videos.append(contentsOf: fresh) }
            hasMore = list.count >= 20
            currentPage += 1
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func refresh() async {
        currentPage = 1; seenIDs.removeAll()
        // 尝试推荐接口，失败回退热门
        await loadRecommend()
        if videos.isEmpty { currentPage = 1; await loadPopular() }
    }

    func loadMoreIfNeeded(current video: Video) async {
        guard hasMore, !isLoading, let idx = videos.firstIndex(where: { $0.id == video.id }), idx >= videos.count - 3 else { return }
        await loadPopular()
    }
}

/// 推荐接口响应（data.item[]）
private struct RecommendResp: Decodable {
    let item: [Video]?
}
