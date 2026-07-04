import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var seenIDs = Set<String>()
    private var currentPage = 1
    private var hasMore = true

    // NOTE: We use loadPopular() exclusively (not the recommend API) to keep the
    // feed simple and deterministic.  If the recommend API
    // (/x/web-interface/wbi/index/top/feed/rcmd) is ever re-introduced, do NOT
    // pass currentPage as fresh_idx — fresh_idx is a tracking/rolling-index
    // returned by the previous response, not a sequential page number.  B站's
    // recommend items carry an `idx` field meant to be echoed back.  Using an
    // arbitrary fresh_idx returns semi-random results.

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

    func refresh() async {
        currentPage = 1; seenIDs.removeAll()
        await loadPopular()
    }

    func loadMoreIfNeeded(current video: Video) async {
        guard hasMore, !isLoading, let idx = videos.firstIndex(where: { $0.id == video.id }), idx >= videos.count - 3 else { return }
        await loadPopular()
    }
}
