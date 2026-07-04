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
    let bvid: String
    let title: String
    let pic: String
    let duration: Int
    let ownerName: String
    let ownerFace: String
    let viewCount: Int
    let timestamp: Date

    init(video: Video, timestamp: Date) {
        self.id = UUID()
        self.bvid = video.bvid
        self.title = video.title
        self.pic = video.pic
        self.duration = video.duration
        self.ownerName = video.owner.name
        self.ownerFace = video.owner.face
        self.viewCount = video.stat.view
        self.timestamp = timestamp
    }

    var video: Video {
        Video(aid: 0, bvid: bvid, title: title, pic: pic, duration: duration,
              owner: VideoOwner(mid: 0, name: ownerName, face: ownerFace),
              stat: VideoStat(view: viewCount, danmaku: 0, reply: 0, favorite: 0, like: 0, coin: 0, share: 0),
              pubdate: 0, desc: nil, cid: nil)
    }
}
