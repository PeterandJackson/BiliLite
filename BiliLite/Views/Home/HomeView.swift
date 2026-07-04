import SwiftUI

/// 首页 — 热门视频 Feed
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // 错误提示
                    if let error = viewModel.errorMessage, viewModel.videos.isEmpty {
                        ErrorBanner(message: error) {
                            Task { await viewModel.refresh() }
                        }
                    }

                    ForEach(viewModel.videos) { video in
                        NavigationLink(value: video) {
                            VideoCard(video: video)
                        }
                        .buttonStyle(.plain)
                        .task {
                            await viewModel.loadMoreIfNeeded(current: video)
                        }
                    }

                    if viewModel.isLoading {
                        LoadMoreView()
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("热门")
            .navigationDestination(for: Video.self) { video in
                VideoDetailView(bvid: video.bvid)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .background(Color(.systemGroupedBackground))
        }
        .task {
            await viewModel.loadPopular()
        }
    }
}
