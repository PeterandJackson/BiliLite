import SwiftUI

struct VideoDetailView: View {
    let bvid: String
    @State private var displayedBvid: String
    @StateObject private var detailVM: VideoDetailViewModel
    @StateObject private var playerVM = PlayerViewModel()
    @StateObject private var favVM = FavoritesViewModel()
    @State private var selectedPage = 0
    @State private var danmakuItems: [DanmakuItem] = []
    @State private var showDanmaku = true
    @State private var isLiked = false; @State private var isCoined = false
    @State private var hasLogin: Bool = false
    @State private var relatedIndex = 0

    init(bvid: String) {
        self.bvid = bvid
        _displayedBvid = State(initialValue: bvid)
        _detailVM = StateObject(wrappedValue: VideoDetailViewModel(bvid: bvid))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let e = detailVM.errorMessage { ErrorBanner(message: e) { Task { await detailVM.load() } }.padding(.top, 8) }
                if detailVM.isLoading && detailVM.detail == nil { LoadingView(message: "加载…").frame(height: 300) }
                if let d = detailVM.detail {
                    playerSection(d)
                    infoSection(d)
                    Divider().padding(.horizontal)
                    actionBar(d)
                    Divider().padding(.horizontal)
                    descriptionSection(d)
                    Divider().padding(.horizontal)
                    pageSection(d)
                    Divider().padding(.horizontal)
                    commentsLink(d)
                    Divider()
                    relatedVideosSection
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .task {
            relatedIndex = 0
            await detailVM.load()
            favVM.loadFavorites(); favVM.loadHistory()
            hasLogin = KeychainHelper.read(key: "bili_sessdata")?.isEmpty == false
            if let d = detailVM.detail {
                favVM.addHistory(Video(aid: d.aid, bvid: d.bvid, title: d.title, pic: d.pic, duration: d.duration, owner: d.owner, stat: d.stat, pubdate: d.pubdate, desc: d.desc, cid: d.currentCID))
            }
            if let c = detailVM.detail?.currentCID {
                await playerVM.play(bvid: displayedBvid, cid: c)
                if let it = try? await DanmakuParser.shared.fetchDanmaku(cid: c) { danmakuItems = it }
            }
            playerVM.onVideoEnded = { autoPlayNextIfNeeded() }
        }
        .onChange(of: displayedBvid) { newBvid in
            guard newBvid != detailVM.bvid else { return }
            relatedIndex = 0; selectedPage = 0; danmakuItems = []
            isLiked = false; isCoined = false
            await detailVM.reload(bvid: newBvid)
            if let d = detailVM.detail {
                favVM.addHistory(Video(aid: d.aid, bvid: d.bvid, title: d.title, pic: d.pic, duration: d.duration, owner: d.owner, stat: d.stat, pubdate: d.pubdate, desc: d.desc, cid: d.currentCID))
            }
            if let c = detailVM.detail?.currentCID {
                await playerVM.play(bvid: newBvid, cid: c)
                if let it = try? await DanmakuParser.shared.fetchDanmaku(cid: c) { danmakuItems = it }
            }
        }
        .onChange(of: selectedPage) { idx in
            guard let pages = detailVM.detail?.pages, idx < pages.count else { return }
            let c = pages[idx].cid
            Task { await playerVM.play(bvid: displayedBvid, cid: c); if let it = try? await DanmakuParser.shared.fetchDanmaku(cid: c) { danmakuItems = it } }
        }
        .onChange(of: playerVM.isPlaying) { playing in
            if !playing { relatedIndex = detailVM.relatedVideos.count }  // user paused: stop auto-play progression
        }
        .onDisappear { playerVM.stop() }
    }

    private func autoPlayNextIfNeeded() {
        let videos = detailVM.relatedVideos
        guard relatedIndex < videos.count else { return }
        let next = videos[relatedIndex]
        relatedIndex += 1

        // Trigger a full page data reload for the new bvid.
        // This updates detailVM.detail (title, stats, owner, desc),
        // relatedVideos, and restarts playback with correct danmaku.
        displayedBvid = next.bvid
    }

    // MARK: - 播放器
    private func playerSection(_ d: VideoDetail) -> some View {
        VStack(spacing: 0) {
            if playerVM.isLoading { ZStack { Color.black; LoadingView(message: "加载…").foregroundColor(.white) }.aspectRatio(16/9, contentMode: .fit) }
            else {
                ZStack {
                    VideoPlayerView(vm: playerVM)
                    if showDanmaku && !danmakuItems.isEmpty { DanmakuView(items: danmakuItems, currentTime: playerVM.currentTime).allowsHitTesting(false) }
                }
                .aspectRatio(16/9, contentMode: .fit)
                HStack(spacing: 12) {
                    Toggle("弹幕", isOn: $showDanmaku).font(.caption).toggleStyle(.switch).tint(.pink)
                    Toggle("联播", isOn: $playerVM.autoPlayNext).font(.caption).toggleStyle(.switch).tint(.pink)
                    Spacer()
                    if playerVM.availableQualities.count > 1 {
                        Menu { ForEach(playerVM.availableQualities, id: \.rawValue) { q in Button(q.label) { Task { await playerVM.switchQuality(q) } } } }
                        label: { Label(playerVM.currentQuality.label, systemImage: "gearshape").font(.caption) }
                    }
                }.padding(.horizontal, 12).padding(.vertical, 6).background(Color(.systemBackground))
            }
        }
    }

    // MARK: - 信息
    private func infoSection(_ d: VideoDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(d.title).font(.headline).lineLimit(3).padding(.horizontal)
            HStack(spacing: 16) {
                Label(d.stat.view.biliFormatted, systemImage: "play.rectangle")
                Label(d.stat.danmaku.biliFormatted, systemImage: "text.bubble")
                Label(d.stat.like.biliFormatted, systemImage: "hand.thumbsup")
                Label(d.stat.coin.biliFormatted, systemImage: "bitcoinsign")
                if let t = d.tname { Label(t, systemImage: "rectangle.grid.1x2") }
            }.font(.caption).foregroundColor(.secondary).padding(.horizontal)
            HStack(spacing: 10) {
                CachedAsyncImage(url: d.owner.faceURL).frame(width: 40, height: 40).clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) { Text(d.owner.name).font(.subheadline.bold()); Text("\(d.pubdate.relativeDate)").font(.caption).foregroundColor(.secondary) }
                Spacer()
                // 收藏
                Button { toggleFav(d) } label: { Image(systemName: favVM.isFavorited(d.bvid) ? "star.fill" : "star").font(.title3).foregroundColor(favVM.isFavorited(d.bvid) ? .yellow : .secondary) }
            }.padding(.horizontal)
        }.padding(.vertical, 12).background(Color(.systemBackground))
    }

    // MARK: - 操作栏（点赞投币分享）
    private func actionBar(_ d: VideoDetail) -> some View {
        HStack(spacing: 0) {
            actionButton("hand.thumbsup", "点赞 \(d.stat.like.biliFormatted)", isActive: isLiked) {
                if hasLogin { isLiked.toggle() } else { /* 弹登录 */ }
            }
            actionButton("bitcoinsign", "投币 \(d.stat.coin.biliFormatted)", isActive: isCoined) {
                if hasLogin { isCoined.toggle() } else {}
            }
            actionButton("star", "收藏 \(d.stat.favorite.biliFormatted)", isActive: favVM.isFavorited(d.bvid)) { toggleFav(d) }
            actionButton("square.and.arrow.up", "分享", isActive: false) {
                let text = "https://www.bilibili.com/video/\(d.bvid)"
                let av = UIActivityViewController(activityItems: [URL(string: text)!], applicationActivities: nil)
                UIApplication.shared.connectedScenes.first.flatMap { ($0 as? UIWindowScene)?.windows.first?.rootViewController?.present(av, animated: true) }
            }
        }.padding(.vertical, 4).background(Color(.systemBackground))
    }

    private func actionButton(_ icon: String, _ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isActive ? "\(icon).fill" : icon).font(.title3).foregroundColor(isActive ? .pink : .secondary)
                Text(label).font(.system(size: 10)).foregroundColor(.secondary)
            }
        }.frame(maxWidth: .infinity)
    }

    private func toggleFav(_ d: VideoDetail) {
        let v = Video(aid: d.aid, bvid: d.bvid, title: d.title, pic: d.pic, duration: d.duration, owner: d.owner, stat: d.stat, pubdate: d.pubdate, desc: d.desc, cid: d.currentCID)
        if favVM.isFavorited(d.bvid) { favVM.removeFavorite(v) } else { favVM.addFavorite(v) }
    }

    @ViewBuilder private func descriptionSection(_ d: VideoDetail) -> some View {
        let desc = d.descStripped
        if !desc.isEmpty { VStack(alignment: .leading, spacing: 6) { Text("简介").font(.subheadline.bold()); Text(desc).font(.subheadline).foregroundColor(.secondary).lineLimit(5) }.padding().background(Color(.systemBackground)) }
    }
    @ViewBuilder private func pageSection(_ d: VideoDetail) -> some View {
        if let p = d.pages, p.count > 1 { VStack(alignment: .leading, spacing: 8) { Text("分P (\(p.count))").font(.subheadline.bold()).padding(.horizontal); ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(Array(p.enumerated()), id: \.offset) { i, pg in Button { selectedPage = i } label: { Text(pg.part).font(.caption).lineLimit(1).padding(.horizontal, 12).padding(.vertical, 8).background(i == selectedPage ? Color.pink : Color(.systemGray5)).foregroundColor(i == selectedPage ? .white : .primary).clipShape(Capsule()) }.buttonStyle(.plain) } }.padding(.horizontal) } }.padding(.vertical, 12).background(Color(.systemBackground)) } }
    private func commentsLink(_ d: VideoDetail) -> some View {
        NavigationLink { CommentListView(oid: d.aid, upperName: d.owner.name) } label: { HStack { Text("评论 (\(d.stat.reply.biliFormatted))").font(.subheadline.bold()).foregroundColor(.primary); Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary) }.padding().background(Color(.systemBackground)) }
    }
    private var relatedVideosSection: some View {
        VStack(alignment: .leading, spacing: 8) { Text("相关视频").font(.headline).padding(.horizontal).padding(.top, 8); LazyVStack(spacing: 12) { ForEach(detailVM.relatedVideos) { v in NavigationLink(value: v) { VideoCard(video: v) }.buttonStyle(.plain) } } }.background(Color(.systemBackground)).padding(.top, 4)
    }
}
