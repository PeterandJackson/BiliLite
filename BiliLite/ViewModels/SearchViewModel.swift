import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [BiliSearchVideoItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    @Published var numResults = 0
    @Published var hotSearches: [String] = []
    @Published var searchHistory: [String] = []

    private var currentPage = 1; private var hasMore = false; private var searchTask: Task<Void, Never>?
    private let histKey = "search_history"

    func loadHotSearches() async {
        do {
            let resp: BiliHotSearchResp = try await BiliAPIClient.shared.get(BiliAPI.hotSearch)
            hotSearches = resp.trending?.list?.map(\.keyword) ?? resp.list?.map(\.keyword) ?? []
        } catch {}
    }

    func loadHistory() { searchHistory = UserDefaults.standard.stringArray(forKey: histKey) ?? [] }
    private func saveHistory() { UserDefaults.standard.set(searchHistory, forKey: histKey) }

    func addToHistory(_ kw: String) {
        searchHistory.removeAll { $0 == kw }; searchHistory.insert(kw, at: 0)
        if searchHistory.count > 50 { searchHistory = Array(searchHistory.prefix(50)) }
        saveHistory()
    }
    func deleteHistory(_ kw: String) { searchHistory.removeAll { $0 == kw }; saveHistory() }
    func clearHistory() { searchHistory.removeAll(); saveHistory() }

    func search(_ keyword: String) async {
        let kw = keyword.trimmingCharacters(in: .whitespaces)
        guard !kw.isEmpty else { return }
        query = kw
        isLoading = true; errorMessage = nil; hasSearched = true; currentPage = 1
        do {
            let resp: BiliSearchData = try await BiliAPIClient.shared.getWBI(BiliAPI.search, params: ["keyword": kw, "search_type": "video", "page": "1", "order": "click"])
            results = resp.result?.first(where: { $0.resultType == "video" })?.data ?? []
            numResults = resp.numResults ?? results.count
            hasMore = results.count >= 20
            addToHistory(kw)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        isLoading = true; currentPage += 1
        do {
            let resp: BiliSearchData = try await BiliAPIClient.shared.getWBI(BiliAPI.search, params: ["keyword": query.trimmingCharacters(in: .whitespaces), "search_type": "video", "page": "\(currentPage)", "order": "click"])
            let videoItems = resp.result?.first(where: { $0.resultType == "video" })?.data ?? []
            results.append(contentsOf: videoItems)
            hasMore = videoItems.count >= 20
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}

// 热搜模型 — executeWithRetry 已提取 B站 code/data 信封，此处直接对映 inner data 的字段
private struct BiliHotSearchResp: Decodable {
    let trending: HotList?
    let list: [HotItem]?
    struct HotList: Decodable { let list: [HotItem]? }
    struct HotItem: Decodable { let keyword: String }
}
