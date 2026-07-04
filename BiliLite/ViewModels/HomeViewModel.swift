import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentPage = 1
    private var hasMore = true
    private let pageSize = 20

    func loadPopular() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let pop: PopularResponse = try await BiliAPIClient.shared.get(
                BiliAPI.popular,
                params: ["pn": "\(currentPage)", "ps": "\(pageSize)"]
            )
            if currentPage == 1 {
                videos = pop.list
            } else {
                videos.append(contentsOf: pop.list)
            }
            hasMore = pop.list.count >= pageSize && !(pop.noMore ?? false)
            currentPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        currentPage = 1
        hasMore = true
        await loadPopular()
    }

    func loadMoreIfNeeded(current video: Video) async {
        guard hasMore, !isLoading else { return }
        // 倒数第 3 个触发预加载
        if let index = videos.firstIndex(where: { $0.id == video.id }),
           index >= videos.count - 3 {
            await loadPopular()
        }
    }
}
