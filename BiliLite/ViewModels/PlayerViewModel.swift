import SwiftUI
import AVFoundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var timeObserver: Any?
    private var currentURL: URL?

    /// 加载并播放视频
    func play(bvid: String, cid: Int, quality: BiliQuality = .p480) async {
        isLoading = true
        errorMessage = nil

        do {
            let stream: VideoStream = try await BiliAPIClient.shared.getWBI(
                BiliAPI.playURL,
                params: [
                    "bvid": bvid,
                    "cid": "\(cid)",
                    "qn": "\(quality.rawValue)",
                    "fnval": "1",       // MP4 模式
                    "fnver": "0",
                    "fourk": "0"
                ]
            )

            guard let url = stream.firstURL else {
                errorMessage = "未能获取播放地址"
                isLoading = false
                return
            }

            currentURL = url
            setupPlayer(with: url)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func setupPlayer(with url: URL) {
        // 复用播放器
        if player == nil {
            player = AVPlayer()
        }

        // 配置 headers（CDN 需要 Referer）
        var request = URLRequest(url: url)
        request.setValue(BiliAPI.referer, forHTTPHeaderField: "Referer")
        request.setValue(BiliAPI.userAgent, forHTTPHeaderField: "User-Agent")

        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [
                "Referer": BiliAPI.referer,
                "User-Agent": BiliAPI.userAgent
            ]
        ])

        let item = AVPlayerItem(asset: asset)
        player?.replaceCurrentItem(with: item)

        // 时间观察
        removeTimeObserver()
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            if let d = self?.player?.currentItem?.duration, d.isNumeric {
                self?.duration = d.seconds
            }
        }

        // 监听播放结束
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
        }

        player?.play()
        isPlaying = true
    }

    // MARK: - 控制

    func togglePlayPause() {
        guard let p = player else { return }
        if p.rate > 0 {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            isPlaying = true
        }
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

    func seekForward(_ seconds: Double = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    func seekBackward(_ seconds: Double = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        removeTimeObserver()
        isPlaying = false
    }

    private func removeTimeObserver() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
        }
    }

    deinit {
        // AVPlayer time observer cleanup — called from non-isolated context OK
        if let obs = timeObserver, let p = player {
            p.removeTimeObserver(obs)
        }
    }
}
