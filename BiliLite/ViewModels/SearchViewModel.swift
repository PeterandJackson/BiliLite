import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [BiliSearchVideoItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    @Published var numResults = 0

    private var currentPage = 1
    private var hasMore = false
    private var searchTask: Task<Void, Never>?

    /// 搜索（300ms debounce）
    func onQueryChanged() {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            hasSearched = false
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)  // 300ms
            guard !Task.isCancelled else { return }
            await self?.search()
        }
    }

    func search() async {
        let keyword = query.trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        hasSearched = true
        currentPage = 1

        do {
            let response: BiliSearchData = try await BiliAPIClient.shared.getWBI(
                BiliAPI.search,
                params: [
                    "keyword": keyword,
                    "search_type": "video",
                    "page": "1",
                    "order": "click"
                ]
            )

            results = response.result?.first?.data ?? []
            numResults = response.numResults ?? results.count
            hasMore = results.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        isLoading = true
        currentPage += 1

        do {
            let response: BiliSearchData = try await BiliAPIClient.shared.getWBI(
                BiliAPI.search,
                params: [
                    "keyword": query.trimmingCharacters(in: .whitespaces),
                    "search_type": "video",
                    "page": "\(currentPage)",
                    "order": "click"
                ]
            )

            let new = response.result?.first?.data ?? []
            results.append(contentsOf: new)
            hasMore = new.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
