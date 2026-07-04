import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
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
            if hasMore { currentPage += 1 }
        } catch {
            if currentPage == 1 { errorMessage = error.localizedDescription }
            // 翻页失败静默处理，不丢已有数据
        }
        isLoading = false
    }

    func refresh() async {
        currentPage = 1; seenIDs.removeAll(); hasMore = true
        await loadPopular()
    }

    func loadMoreIfNeeded(current video: Video) async {
        guard hasMore, !isLoading, let idx = videos.firstIndex(where: { $0.id == video.id }), idx >= videos.count - 3 else { return }
        await loadPopular()
    }
}
