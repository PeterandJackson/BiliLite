import SwiftUI

/// 搜索页
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                searchBar

                // 内容区
                if viewModel.isLoading {
                    Spacer()
                    LoadingView(message: "搜索中…")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    ErrorBanner(message: error) {
                        Task { await viewModel.search() }
                    }
                    Spacer()
                } else if !viewModel.hasSearched {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("搜索你想看的视频")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if viewModel.results.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("没有找到相关视频")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    resultList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: String.self) { bvid in
                VideoDetailView(bvid: bvid)
            }
        }
    }

    // MARK: - 搜索栏

    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索视频", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await viewModel.search() }
                    }
                    .onChange(of: viewModel.query) { _ in
                        viewModel.onQueryChanged()
                    }

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                        viewModel.results = []
                        viewModel.hasSearched = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 结果列表

    private var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // 结果计数
                Text("共 \(viewModel.numResults) 个结果")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 4)

                ForEach(viewModel.results) { item in
                    if let bvid = item.bvid {
                        NavigationLink(value: bvid) {
                            searchResultRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if viewModel.isLoading {
                    LoadMoreView()
                }
            }
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func searchResultRow(_ item: BiliSearchVideoItem) -> some View {
        HStack(spacing: 12) {
            // 封面
            CachedAsyncImage(url: item.coverURL)
                .frame(width: 140, height: 79)  // 16:9
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                if let author = item.author {
                    Text(author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    if let play = item.play {
                        Label(play.biliFormatted, systemImage: "play.rectangle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let danmaku = item.danmaku {
                        Label(danmaku.biliFormatted, systemImage: "text.bubble")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let duration = item.duration {
                        Text(duration)
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
    }
}
