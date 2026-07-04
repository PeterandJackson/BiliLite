import SwiftUI

/// 动态/关注页面 — 展示关注UP主的投稿动态
struct DynamicView: View {
    @StateObject private var viewModel = DynamicViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    LoadingView(message: "加载动态…").padding(.top, 100)
                } else if let error = viewModel.errorMessage, viewModel.items.isEmpty {
                    ErrorBanner(message: error) { Task { await viewModel.load() } }.padding(.top, 40)
                } else if viewModel.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash").font(.system(size: 48)).foregroundColor(.secondary)
                        Text("暂无动态").foregroundColor(.secondary)
                        Text("关注你喜欢的UP主，这里会出现TA的最新动态").font(.caption).foregroundColor(.secondary)
                    }.padding(.top, 120)
                } else {
                    dynamicList
                }
            }
            .navigationTitle("动态")
            .background(Color(.systemGroupedBackground))
            .task { if viewModel.items.isEmpty { await viewModel.load() } }
            .refreshable { await viewModel.refresh() }
        }
    }

    private var dynamicList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.items) { item in
                    dynamicCard(item)
                        .task { await viewModel.loadMoreIfNeeded(current: item) }
                }
                if viewModel.isLoading { LoadMoreView() }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func dynamicCard(_ item: DynamicItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 作者行
            if let author = item.modules?.moduleAuthor {
                HStack(spacing: 8) {
                    CachedAsyncImage(url: URL(string: (author.face ?? "").replacingOccurrences(of: "http://", with: "https://")))
                        .frame(width: 36, height: 36).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(author.name ?? "").font(.subheadline.bold())
                        Text(author.pubAction ?? author.pubTime ?? "").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }

            // 描述
            if let desc = item.modules?.moduleDynamic?.desc?.text, !desc.isEmpty {
                Text(desc).font(.subheadline).lineLimit(4).foregroundColor(.primary)
            }

            // 视频卡片
            if let archive = item.modules?.moduleDynamic?.major?.archive {
                HStack(spacing: 10) {
                    CachedAsyncImage(url: URL(string: (archive.cover ?? "").replacingOccurrences(of: "http://", with: "https://")))
                        .frame(width: 140, height: 79).clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(archive.title ?? "").font(.subheadline).lineLimit(2)
                        HStack(spacing: 12) {
                            if let p = archive.play { Label(p.biliFormatted, systemImage: "play.rectangle").font(.caption2).foregroundColor(.secondary) }
                            if let d = archive.danmaku { Label(d.biliFormatted, systemImage: "text.bubble").font(.caption2).foregroundColor(.secondary) }
                        }
                        if let dur = archive.durationText { Text(dur).font(.caption2).foregroundColor(.secondary) }
                    }
                }
                .padding(8).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    NavigationLink(destination: archive.bvid.map { bv in
                        AnyView(VideoDetailView(bvid: bv))
                    } ?? AnyView(EmptyView())) { EmptyView() }.opacity(0)
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 8)
    }
}

// MARK: - ViewModel

@MainActor
final class DynamicViewModel: ObservableObject {
    @Published var items: [DynamicItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var offset: String?
    private var hasMore = true

    func load() async {
        guard !isLoading else { return }
        isLoading = true; errorMessage = nil
        do {
            let resp: DynamicFeedResp = try await BiliAPIClient.shared.get(BiliAPI.dynamic, params: ["type": "all"])
            items = resp.items ?? []
            hasMore = resp.hasMore ?? false
            offset = resp.offset
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refresh() async {
        offset = nil; hasMore = true; items = []
        await load()
    }

    func loadMoreIfNeeded(current item: DynamicItem) async {
        guard hasMore, !isLoading,
              let idx = items.firstIndex(where: { $0.id == item.id }),
              idx >= items.count - 3 else { return }
        isLoading = true
        var params: [String: String] = ["type": "all"]
        if let o = offset { params["offset"] = o }
        do {
            let resp: DynamicFeedResp = try await BiliAPIClient.shared.get(BiliAPI.dynamic, params: params)
            if let new = resp.items { items.append(contentsOf: new) }
            hasMore = resp.hasMore ?? false
            offset = resp.offset
        } catch {}
        isLoading = false
    }
}
