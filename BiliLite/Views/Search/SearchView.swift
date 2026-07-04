import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("搜索视频", text: $searchText).textFieldStyle(.plain).autocorrectionDisabled().submitLabel(.search)
                            .onSubmit { Task { await vm.search(searchText) } }
                        if !searchText.isEmpty { Button { searchText = ""; vm.results = []; vm.hasSearched = false } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) } }
                    }.padding(10).background(Color(.systemGray5)).clipShape(RoundedRectangle(cornerRadius: 10))
                    if !searchText.isEmpty {
                        Button("搜索") { Task { await vm.search(searchText) } }.font(.subheadline.bold()).foregroundColor(.pink)
                    }
                }.padding(.horizontal).padding(.vertical, 8).background(Color(.systemBackground))

                if vm.hasSearched {
                    resultList
                } else {
                    // 搜索前：热搜 + 历史
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !vm.searchHistory.isEmpty { historySection }
                            if !vm.hotSearches.isEmpty { hotSearchSection }
                        }.padding()
                    }
                }
            }.background(Color(.systemGroupedBackground))
        }
        .task { vm.loadHistory(); await vm.loadHotSearches() }
    }

    // MARK: - 热搜
    private var hotSearchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔥 热门搜索").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(vm.hotSearches.prefix(20).enumerated()), id: \.offset) { i, kw in
                    Button { searchText = kw; Task { await vm.search(kw) } } label: {
                        HStack(spacing: 4) {
                            Text("\(i + 1)").font(.system(size: 11, weight: .bold)).foregroundColor(i < 3 ? .pink : .secondary)
                            Text(kw).font(.caption).lineLimit(1).foregroundColor(.primary)
                            Spacer()
                        }.padding(8).background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 历史
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("🕐 搜索历史").font(.headline); Spacer(); Button("清空") { vm.clearHistory() }.font(.caption).foregroundColor(.red) }
            ForEach(vm.searchHistory, id: \.self) { kw in
                HStack {
                    Button { searchText = kw; Task { await vm.search(kw) } } label: { Text(kw).font(.subheadline).foregroundColor(.primary).lineLimit(1) }.buttonStyle(.plain)
                    Spacer()
                    Button { vm.deleteHistory(kw) } label: { Image(systemName: "xmark").font(.caption).foregroundColor(.secondary) }
                }.padding(.vertical, 4).padding(.horizontal, 8).background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // MARK: - 结果
    private var resultList: some View {
        ScrollView {
            if vm.isLoading { LoadingView(message: "搜索中…").padding(.top, 40) }
            else if let e = vm.errorMessage { ErrorBanner(message: e) { Task { await vm.search(searchText) } }.padding(.top, 8) }
            else if vm.results.isEmpty { VStack(spacing: 8) { Image(systemName: "video.slash").font(.system(size: 40)).foregroundColor(.secondary); Text("没有找到视频").foregroundColor(.secondary) }.padding(.top, 80) }
            else {
                Text("共 \(vm.numResults) 个结果").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal).padding(.top, 4)
                LazyVStack(spacing: 12) {
                    ForEach(vm.results) { item in
                        if let bv = item.bvid {
                            NavigationLink(destination: VideoDetailView(bvid: bv)) { searchRow(item) }.buttonStyle(.plain)
                        }
                    }
                    if vm.isLoading { LoadMoreView() }
                }.padding(.bottom, 16)
            }
        }
    }

    @ViewBuilder private func searchRow(_ item: BiliSearchVideoItem) -> some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: item.coverURL).frame(width: 140, height: 79).clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.subheadline).lineLimit(2).foregroundColor(.primary)
                if let a = item.author { Text(a).font(.caption).foregroundColor(.secondary) }
                HStack(spacing: 12) {
                    if let p = item.play { Label(p.biliFormatted, systemImage: "play.rectangle").font(.caption2).foregroundColor(.secondary) }
                    if let d = item.danmaku { Label(d.biliFormatted, systemImage: "text.bubble").font(.caption2).foregroundColor(.secondary) }
                }
            }
        }.padding(.horizontal)
    }
}
