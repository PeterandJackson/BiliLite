import SwiftUI

/// 主导航 — 首页 / 搜索 / 我的
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("首页")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("搜索")
                }
                .tag(1)

            ProfilePlaceholderView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                    Text("我的")
                }
                .tag(2)
        }
    }
}

/// 我的 — 占位页
struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)

                Text("登录后可查看更多内容")
                    .font(.headline)

                Text("目前以游客模式浏览\n可观看 480P 画质视频")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // 后续可在此添加收藏、历史等功能
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundColor(.pink)
                        Text("观看历史")
                            .font(.caption)
                    }

                    VStack {
                        Image(systemName: "star")
                            .font(.title3)
                            .foregroundColor(.pink)
                        Text("我的收藏")
                            .font(.caption)
                    }

                    VStack {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(.pink)
                        Text("设置")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
            .navigationTitle("我的")
            .frame(maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }
}
