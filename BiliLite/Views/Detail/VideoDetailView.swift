import SwiftUI

struct VideoDetailView: View {
    let bvid: String
    @StateObject private var detailVM: VideoDetailViewModel
    @StateObject private var playerVM = PlayerViewModel()
    @StateObject private var favVM = FavoritesViewModel()
    @State private var selectedPage = 0
    @State private var danmakuItems: [DanmakuItem] = []
    @State private var showDanmaku = true

    init(bvid: String) {
        self.bvid = bvid
        _detailVM = StateObject(wrappedValue: VideoDetailViewModel(bvid: bvid))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let error = detailVM.errorMessage {
                    ErrorBanner(message: error) { Task { await detailVM.load() } }.padding(.top, 8)
                }
                if detailVM.isLoading && detailVM.detail == nil {
                    LoadingView(message: "加载中…").frame(height: 300)
                }
                if let detail = detailVM.detail {
                    playerSection(detail)
                    infoSection(detail)
                    Divider().padding(.horizontal)
                    descriptionSection(detail)
                    Divider().padding(.horizontal)
                    pageSection(detail)
                    Divider().padding(.horizontal)
                    commentsLink(detail)
                    Divider()
                    relatedVideosSection
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .task {
            await detailVM.load()
            favVM.loadFavorites(); favVM.loadHistory()
            if let detail = detailVM.detail {
                let v = Video(aid: detail.aid, bvid: detail.bvid, title: detail.title, pic: detail.pic,
                               duration: detail.duration, owner: detail.owner, stat: detail.stat,
                               pubdate: detail.pubdate, desc: detail.desc, cid: detail.currentCID)
                favVM.addHistory(v)
            }
            if let cid = detailVM.detail?.currentCID {
                await playerVM.play(bvid: bvid, cid: cid)
                if let items = try? await DanmakuParser.shared.fetchDanmaku(cid: cid) {
                    danmakuItems = items
                }
            }
        }
        .onChange(of: selectedPage) { idx in
            guard let pages = detailVM.detail?.pages, idx < pages.count else { return }
            let cid = pages[idx].cid
            Task {
                await playerVM.play(bvid: bvid, cid: cid)
                if let items = try? await DanmakuParser.shared.fetchDanmaku(cid: cid) {
                    danmakuItems = items
                }
            }
        }
        .onDisappear { playerVM.stop() }
    }

    // MARK: - 播放器
    private func playerSection(_ detail: VideoDetail) -> some View {
        VStack(spacing: 0) {
            if playerVM.isLoading {
                ZStack { Color.black; LoadingView(message: "加载播放器…").foregroundColor(.white) }
                    .aspectRatio(16/9, contentMode: .fit)
            } else {
                ZStack {
                    VideoPlayerView(vm: playerVM)
                    // 弹幕层
                    if showDanmaku && !danmakuItems.isEmpty {
                        DanmakuView(items: danmakuItems, currentTime: playerVM.currentTime)
                            .allowsHitTesting(false)
                    }
                }
                .aspectRatio(16/9, contentMode: .fit)

                // 弹幕开关
                HStack(spacing: 12) {
                    Toggle("弹幕", isOn: $showDanmaku).font(.caption).toggleStyle(.switch).tint(.pink)
                    Spacer()
                    // 高清切换
                    if playerVM.availableQualities.count > 1 {
                        Menu {
                            ForEach(playerVM.availableQualities, id: \.rawValue) { q in
                                Button(q.label) { Task { await playerVM.switchQuality(q) } }
                            }
                        } label: {
                            Label(playerVM.currentQuality.label, systemImage: "gearshape").font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color(.systemBackground))
            }
        }
    }

    // MARK: - 视频信息
    private func infoSection(_ detail: VideoDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(detail.title).font(.headline).lineLimit(3).padding(.horizontal)
            HStack(spacing: 16) {
                Label(detail.stat.view.biliFormatted, systemImage: "play.rectangle")
                Label(detail.stat.danmaku.biliFormatted, systemImage: "text.bubble")
                Label(detail.stat.like.biliFormatted, systemImage: "hand.thumbsup")
                Label(detail.stat.coin.biliFormatted, systemImage: "bitcoinsign")
                if let tname = detail.tname { Label(tname, systemImage: "rectangle.grid.1x2") }
            }
            .font(.caption).foregroundColor(.secondary).padding(.horizontal)

            HStack(spacing: 10) {
                CachedAsyncImage(url: detail.owner.faceURL).frame(width: 40, height: 40).clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(detail.owner.name).font(.subheadline.bold())
                    Text("\(detail.pubdate.relativeDate) 发布").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                // 收藏按钮
                Button(action: {
                    let v = Video(aid: detail.aid, bvid: detail.bvid, title: detail.title, pic: detail.pic,
                                   duration: detail.duration, owner: detail.owner, stat: detail.stat,
                                   pubdate: detail.pubdate, desc: detail.desc, cid: detail.currentCID)
                    if favVM.isFavorited(detail.bvid) { favVM.removeFavorite(v) }
                    else { favVM.addFavorite(v) }
                }) {
                    Image(systemName: favVM.isFavorited(detail.bvid) ? "star.fill" : "star")
                        .font(.title3).foregroundColor(favVM.isFavorited(detail.bvid) ? .yellow : .secondary)
                }
                .padding(.trailing)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12).background(Color(.systemBackground))
    }

    // MARK: - 简介
    @ViewBuilder
    private func descriptionSection(_ detail: VideoDetail) -> some View {
        let desc = detail.descStripped
        if !desc.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("简介").font(.subheadline.bold())
                Text(desc).font(.subheadline).foregroundColor(.secondary).lineLimit(5)
            }.padding().background(Color(.systemBackground))
        }
    }

    // MARK: - 分P
    @ViewBuilder
    private func pageSection(_ detail: VideoDetail) -> some View {
        if let pages = detail.pages, pages.count > 1 {
            VStack(alignment: .leading, spacing: 8) {
                Text("分P (\(pages.count))").font(.subheadline.bold()).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                            Button {
                                selectedPage = idx
                            } label: {
                                Text(page.part).font(.caption).lineLimit(1)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(idx == selectedPage ? Color.pink : Color(.systemGray5))
                                    .foregroundColor(idx == selectedPage ? .white : .primary)
                                    .clipShape(Capsule())
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal)
                }
            }.padding(.vertical, 12).background(Color(.systemBackground))
        }
    }

    private func commentsLink(_ detail: VideoDetail) -> some View {
        NavigationLink {
            CommentListView(oid: detail.aid, upperName: detail.owner.name)
        } label: {
            HStack {
                Text("评论 (\(detail.stat.reply.biliFormatted))").font(.subheadline.bold()).foregroundColor(.primary)
                Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }.padding().background(Color(.systemBackground))
        }
    }

    private var relatedVideosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("相关视频").font(.headline).padding(.horizontal).padding(.top, 8)
            LazyVStack(spacing: 12) {
                ForEach(detailVM.relatedVideos) { video in
                    NavigationLink(value: video) { VideoCard(video: video) }.buttonStyle(.plain)
                }
            }
        }.background(Color(.systemBackground)).padding(.top, 4)
    }
}
