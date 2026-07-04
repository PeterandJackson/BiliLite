import SwiftUI
import AVFoundation

struct LiveView: View {
    @StateObject private var vm = LiveViewModel()
    @State private var selectedRoom: Int?

    var body: some View {
        NavigationStack {
            Group {
                if let rid = selectedRoom { playerView(rid) }
                else { roomList }
            }.navigationTitle("直播").background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - 房间列表
    private var roomList: some View {
        ScrollView {
            if vm.isLoadingList { LoadingView(message: "加载热门直播…").padding(.top, 40) }
            else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(vm.rooms) { room in
                        Button { selectRoom(room) } label: { roomCard(room) }.buttonStyle(.plain)
                    }
                }.padding()
            }
        }
        .refreshable { await vm.loadRooms() }
        .task { if vm.rooms.isEmpty { await vm.loadRooms() } }
    }

    private func selectRoom(_ room: LiveRoomItem) {
        selectedRoom = room.roomid
        Task { await vm.loadRoom(roomId: room.roomid) }
    }

    private func roomCard(_ room: LiveRoomItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(url: URL(string: (room.cover ?? room.userCover ?? "").replacingOccurrences(of: "http://", with: "https://")))
                    .aspectRatio(16/10, contentMode: .fill).clipShape(RoundedRectangle(cornerRadius: 8))
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 6, height: 6)
                    Text((room.online ?? 0).biliFormatted).font(.system(size: 10)).foregroundColor(.white)
                }.padding(4).background(Color.black.opacity(0.6)).clipShape(Capsule()).padding(4)
            }
            Text(room.title ?? "直播间").font(.caption).lineLimit(2).foregroundColor(.primary)
            Text(room.uname ?? "").font(.caption2).foregroundColor(.secondary)
        }
    }

    // MARK: - 播放器
    private func playerView(_ rid: Int) -> some View {
        VStack(spacing: 0) {
            if vm.isLoading { LoadingView(message: "加载直播间…").frame(height: 300) }
            else if let e = vm.errorMessage { ErrorBanner(message: e) { selectedRoom = nil } }
            else if let _ = vm.player {
                ZStack {
                    LivePlayerView(player: vm.player!)
                    if !vm.danmakuItems.isEmpty { DanmakuView(items: vm.danmakuItems, currentTime: 0).allowsHitTesting(false) }
                }.aspectRatio(16/9, contentMode: .fit).onTapGesture { vm.togglePlayPause() }
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.roomTitle).font(.headline).lineLimit(2)
                    HStack { Text(vm.ownerName).font(.subheadline).foregroundColor(.secondary); Spacer(); HStack(spacing: 4) { Circle().fill(Color.red).frame(width: 8, height: 8); Text("\(vm.onlineCount)").font(.caption).foregroundColor(.secondary) } }
                }.padding()
            }
            Spacer()
            Button("返回列表") { vm.stop(); selectedRoom = nil }.font(.subheadline).foregroundColor(.pink).padding(.bottom, 8)
        }.onDisappear { vm.stop() }
    }
}

private struct LivePlayerView: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> LivePlayerUIView { LivePlayerUIView(player: player) }
    func updateUIView(_ uiView: LivePlayerUIView, context: Context) { uiView.playerLayer.player = player }
}
private final class LivePlayerUIView: UIView {
    let playerLayer = AVPlayerLayer()
    init(player: AVPlayer) { super.init(frame: .zero); playerLayer.player = player; playerLayer.videoGravity = .resizeAspect; layer.addSublayer(playerLayer) }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); playerLayer.frame = bounds }
}
