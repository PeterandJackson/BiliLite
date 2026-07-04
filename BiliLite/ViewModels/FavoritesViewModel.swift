import SwiftUI

/// 收藏 + 历史记录管理
@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [Video] = []
    @Published var history: [HistoryItem] = []
    @Published var isLoading = false

    private let favKey = "bili_favorites"
    private let histKey = "bili_history"

    // MARK: - 本地收藏

    func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favKey),
              let items = try? JSONDecoder().decode([Video].self, from: data)
        else { return }
        favorites = items
    }

    func addFavorite(_ video: Video) {
        if !favorites.contains(where: { $0.bvid == video.bvid }) {
            favorites.insert(video, at: 0)
            saveFavorites()
        }
    }

    func removeFavorite(_ video: Video) {
        favorites.removeAll { $0.bvid == video.bvid }
        saveFavorites()
    }

    func isFavorited(_ bvid: String) -> Bool {
        favorites.contains { $0.bvid == bvid }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: favKey)
        }
    }

    // MARK: - 本地历史

    func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: histKey),
              let items = try? JSONDecoder().decode([HistoryItem].self, from: data)
        else { return }
        history = items
    }

    func addHistory(_ video: Video) {
        let item = HistoryItem(video: video, timestamp: Date())
        history.removeAll { $0.video.bvid == video.bvid }
        history.insert(item, at: 0)
        if history.count > 100 { history = Array(history.prefix(100)) }
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: histKey)
        }
    }

    func clearHistory() { history.removeAll(); UserDefaults.standard.removeObject(forKey: histKey) }
}

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let video: Video
    let timestamp: Date

    init(video: Video, timestamp: Date) {
        self.id = UUID()
        self.video = video
        self.timestamp = timestamp
    }
}
