import SwiftUI
import AVFoundation

struct LiveView: View {
    @StateObject private var vm = LiveViewModel()
    @State private var roomIdText = ""
    @State private var showRoomInput = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showRoomInput {
                    // 直播间号输入
                    VStack(spacing: 16) {
                        Image(systemName: "video.fill.badge.play").font(.system(size: 50)).foregroundColor(.pink)
                        Text("输入直播间号").font(.title3.bold())
                        HStack {
                            TextField("房间号", text: $roomIdText)
                                .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                            Button("进入") {
                                guard let rid = Int(roomIdText), rid > 0 else { return }
                                showRoomInput = false
                                Task { await vm.loadRoom(roomId: rid) }
                            }
                            .font(.headline).foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Color.pink).clipShape(Capsule())
                        }.padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // 播放器
                    if vm.isLoading {
                        LoadingView(message: "加载直播间…").frame(height: 300)
                    } else if let error = vm.errorMessage {
                        ErrorBanner(message: error) {
                            showRoomInput = true
                            roomIdText = ""
                        }
                    } else if let _ = vm.player {
                        VStack(spacing: 0) {
                            ZStack {
                                LivePlayerView(player: vm.player!)
                                if !vm.danmakuItems.isEmpty {
                                    DanmakuView(items: vm.danmakuItems, currentTime: 0)
                                        .allowsHitTesting(false)
                                }
                            }
                            .aspectRatio(16/9, contentMode: .fit)
                            .onTapGesture { vm.togglePlayPause() }

                            // 直播间信息
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vm.roomTitle).font(.headline).lineLimit(2)
                                HStack {
                                    Text(vm.ownerName).font(.subheadline).foregroundColor(.secondary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.red).frame(width: 8, height: 8)
                                        Text("\(vm.onlineCount)").font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }.padding()
                        }
                    }
                    Spacer()
                }
            }
            .navigationTitle("直播")
            .background(Color(.systemGroupedBackground))
            .onDisappear { vm.stop() }
        }
    }
}

private struct LivePlayerView: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> PlayerLayerView { PlayerLayerView(player: player) }
    func updateUIView(_ uiView: PlayerLayerView, context: Context) { uiView.playerLayer.player = player }
}

private final class PlayerLayerView: UIView {
    let playerLayer = AVPlayerLayer()
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player; playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); playerLayer.frame = bounds }
}
