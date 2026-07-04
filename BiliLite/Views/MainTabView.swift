import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var favVM = FavoritesViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house"); Text("首页")
                }.tag(0)

            DynamicView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "bell.fill" : "bell"); Text("动态")
                }.tag(1)

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass"); Text("搜索")
                }.tag(2)

            BangumiView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "play.rectangle.fill" : "play.rectangle"); Text("番剧")
                }.tag(3)

            LiveView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "play.tv.fill" : "play.tv"); Text("直播")
                }.tag(4)

            ProfileView(favVM: favVM)
                .tabItem {
                    Image(systemName: selectedTab == 5 ? "person.fill" : "person"); Text("我的")
                }.tag(5)
        }
        .onAppear { favVM.loadFavorites(); favVM.loadHistory() }
    }
}

// MARK: - 我的页面

struct ProfileView: View {
    @ObservedObject var favVM: FavoritesViewModel
    @State private var showLogin = false
    @State private var hasLogin = false

    var body: some View {
        NavigationStack {
            List {
                // 登录区域
                Section {
                    if hasLogin {
                        HStack {
                            Image(systemName: "person.crop.circle.fill").font(.system(size: 40)).foregroundColor(.pink)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("已登录").font(.headline)
                                Text("享受 1080P 高清画质").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Button(action: { showLogin = true }) {
                            HStack {
                                Image(systemName: "person.crop.circle").font(.system(size: 40)).foregroundColor(.pink)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("点击登录").font(.headline).foregroundColor(.primary)
                                    Text("登录后享 720P/1080P 高清").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                        }
                    }
                    if let sess = KeychainHelper.read(key: "bili_sessdata"), !sess.isEmpty {
                        Text("已保存登录信息 (Cookie)").font(.caption2).foregroundColor(.green)
                    }
                }

                // 收藏
                Section("我的收藏") {
                    if favVM.favorites.isEmpty {
                        HStack { Spacer(); Text("暂无收藏").foregroundColor(.secondary); Spacer() }
                    } else {
                        ForEach(Array(favVM.favorites.prefix(10))) { video in
                            NavigationLink {
                                VideoDetailView(bvid: video.bvid)
                            } label: {
                                HStack(spacing: 10) {
                                    CachedAsyncImage(url: video.coverURL).frame(width: 80, height: 45).clipShape(RoundedRectangle(cornerRadius: 4))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(video.title).font(.subheadline).lineLimit(1)
                                        Text(video.owner.name).font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                // 观看历史
                Section("观看历史") {
                    if favVM.history.isEmpty {
                        HStack { Spacer(); Text("暂无历史").foregroundColor(.secondary); Spacer() }
                    } else {
                        ForEach(Array(favVM.history.prefix(10))) { item in
                            NavigationLink {
                                VideoDetailView(bvid: item.video.bvid)
                            } label: {
                                HStack(spacing: 10) {
                                    CachedAsyncImage(url: item.video.coverURL).frame(width: 80, height: 45).clipShape(RoundedRectangle(cornerRadius: 4))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.video.title).font(.subheadline).lineLimit(1)
                                        Text(item.video.owner.name).font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        Button("清空历史") { favVM.clearHistory() }.font(.caption).foregroundColor(.red)
                    }
                }

                // 离线缓存
                Section("离线缓存") {
                    NavigationLink {
                        DownloadListView()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle").foregroundColor(.pink)
                            Text("离线缓存管理").foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }

                // 关于
                Section {
                    HStack {
                        Text("版本").foregroundColor(.secondary); Spacer(); Text("2.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("目标设备").foregroundColor(.secondary); Spacer(); Text("iPhone X / iOS 16.7").foregroundColor(.secondary)
                    }
                    // 退出登录
                    if hasLogin {
                        Button("退出登录") {
                            KeychainHelper.delete(key: "bili_sessdata")
                            KeychainHelper.delete(key: "bili_uid")
                            KeychainHelper.delete(key: "bili_jct")
                            hasLogin = false
                        }.font(.caption).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("我的")
            .sheet(isPresented: $showLogin) {
                LoginView()
                    .onDisappear {
                        hasLogin = KeychainHelper.read(key: "bili_sessdata")?.isEmpty == false
                    }
            }
            .onAppear {
                hasLogin = KeychainHelper.read(key: "bili_sessdata")?.isEmpty == false
                favVM.loadFavorites(); favVM.loadHistory()
            }
            .onReceive(NotificationCenter.default.publisher(for: .biliLoginSuccess)) { _ in
                hasLogin = true
                favVM.loadFavorites(); favVM.loadHistory()
            }
            .onReceive(NotificationCenter.default.publisher(for: .biliFavoritesChanged)) { _ in
                favVM.loadFavorites()
            }
            .onReceive(NotificationCenter.default.publisher(for: .biliHistoryChanged)) { _ in
                favVM.loadHistory()
            }
        }
    }
}

// MARK: - 离线缓存管理

struct DownloadListView: View {
    @State private var downloadedVideos: [DownloadedItem] = []
    @State private var isLoading = true

    var body: some View {
        List {
            if isLoading {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if downloadedVideos.isEmpty {
                HStack { Spacer(); Text("暂无离线视频").foregroundColor(.secondary); Spacer() }
            } else {
                Section("已下载 (\(downloadedVideos.count))") {
                    ForEach(downloadedVideos) { item in
                        HStack(spacing: 10) {
                            CachedAsyncImage(url: URL(string: item.cover.replacingOccurrences(of: "http://", with: "https://")))
                                .frame(width: 80, height: 45).clipShape(RoundedRectangle(cornerRadius: 4))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.subheadline).lineLimit(1)
                                Text(byteFormatter.string(fromByteCount: item.fileSize)).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { idx in
                        for i in idx { deleteFile(downloadedVideos[i]) }
                        downloadedVideos.remove(atOffsets: idx)
                    }
                }
            }
        }
        .navigationTitle("离线缓存")
        .onAppear { loadDownloads() }
    }

    private func loadDownloads() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("BiliDownloads")
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey]) else {
            isLoading = false; return
        }
        downloadedVideos = files.compactMap { url in
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attrs?[.size] as? Int64) ?? 0
            return DownloadedItem(title: url.deletingPathExtension().lastPathComponent,
                                  cover: "", fileSize: size, url: url)
        }
        isLoading = false
    }

    private func deleteFile(_ item: DownloadedItem) {
        try? FileManager.default.removeItem(at: item.url)
    }
}

struct DownloadedItem: Identifiable {
    let id = UUID()
    let title: String
    let cover: String
    let fileSize: Int64
    let url: URL
}

private let byteFormatter: ByteCountFormatter = {
    let f = ByteCountFormatter(); f.countStyle = .file; return f
}()
