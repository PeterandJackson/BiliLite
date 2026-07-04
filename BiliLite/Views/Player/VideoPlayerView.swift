import SwiftUI
import AVKit

/// 自定义播放器 — 不跟系统 PiP 冲突，支持全屏
struct VideoPlayerView: View {
    @ObservedObject var vm: PlayerViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 视频层
                PlayerLayerView(player: vm.player)
                    .frame(width: geo.size.width, height: geo.size.height)

                // 覆盖层
                PlayerOverlay(viewModel: vm)
            }
        }
        .background(Color.black)
        .onDisappear { vm.stop() }
    }
}

/// AVPlayerLayer 的 SwiftUI 桥接 — 不用 AVPlayerViewController
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerUIView: UIView {
    let playerLayer = AVPlayerLayer()

    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = UIColor.black.cgColor
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
