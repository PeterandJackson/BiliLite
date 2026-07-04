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

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass"); Text("搜索")
                }.tag(1)

            LiveView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "play.tv.fill" : "play.tv"); Text("直播")
                }.tag(2)

            ProfileView(favVM: favVM)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.fill" : "person"); Text("我的")
                }.tag(3)
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
                    if let sess = UserDefaults.standard.string(forKey: "bili_sessdata"), !sess.isEmpty {
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

                // 关于
                Section {
                    HStack {
                        Text("版本").foregroundColor(.secondary); Spacer(); Text("1.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("目标设备").foregroundColor(.secondary); Spacer(); Text("iPhone X / iOS 16.7").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("我的")
            .sheet(isPresented: $showLogin) {
                LoginView()
                    .onDisappear {
                        hasLogin = UserDefaults.standard.string(forKey: "bili_sessdata")?.isEmpty == false
                    }
            }
            .onAppear {
                hasLogin = UserDefaults.standard.string(forKey: "bili_sessdata")?.isEmpty == false
                favVM.loadFavorites(); favVM.loadHistory()
            }
        }
    }
}
