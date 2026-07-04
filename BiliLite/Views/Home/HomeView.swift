import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if let error = viewModel.errorMessage, viewModel.videos.isEmpty {
                    ErrorBanner(message: error) { Task { await viewModel.refresh() } }.padding(.top, 8)
                }
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.videos) { video in
                        NavigationLink(value: video) {
                            VideoCard(video: video)
                        }
                        .buttonStyle(.plain)
                        .task { await viewModel.loadMoreIfNeeded(current: video) }
                    }
                    if viewModel.isLoading { LoadMoreView() }
                }
                .padding(.vertical, 8)
            }
            .refreshable { await viewModel.refresh() }
            .navigationTitle("热门")
            .navigationDestination(for: Video.self) { video in
                VideoDetailView(bvid: video.bvid)
            }
            .background(Color(.systemGroupedBackground))
            .task { if viewModel.videos.isEmpty { await viewModel.loadPopular() } }
        }
    }
}
