import SwiftUI
import AVFoundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var player = AVPlayer()
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentQuality: BiliQuality = .p480
    @Published var availableQualities: [BiliQuality] = [.p360, .p480]
    @Published var isFullscreen = false

    private var timeObserver: Any?
    var currentBvid: String = ""
    var currentCid: Int = 0

    func play(bvid: String, cid: Int, quality: BiliQuality = .p480) async {
        isLoading = true
        errorMessage = nil
        currentBvid = bvid
        currentCid = cid
        currentQuality = quality

        do {
            let stream: VideoStream = try await BiliAPIClient.shared.getWBI(
                BiliAPI.playURL,
                params: [
                    "bvid": bvid, "cid": "\(cid)",
                    "qn": "\(quality.rawValue)", "fnval": "1", "fnver": "0", "fourk": "0"
                ]
            )
            guard let url = stream.firstURL else {
                errorMessage = "未能获取播放地址"; isLoading = false; return
            }
            if let accepted = stream.acceptQuality {
                availableQualities = accepted.compactMap { BiliQuality(rawValue: $0) }
            }
            setupPlayer(with: url)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func switchQuality(_ q: BiliQuality) async {
        currentQuality = q
        await play(bvid: currentBvid, cid: currentCid, quality: q)
    }

    private func setupPlayer(with url: URL) {
        removeTimeObserver()
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [
                "Referer": BiliAPI.referer,
                "User-Agent": BiliAPI.userAgent
            ]
        ])
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            guard let self else { return }
            self.currentTime = t.seconds
            if let d = self.player.currentItem?.duration, d.isNumeric {
                self.duration = d.seconds
            }
        }
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            self?.isPlaying = false
        }
        player.play()
        isPlaying = true
    }

    func togglePlayPause() {
        if player.rate > 0 { player.pause(); isPlaying = false }
        else { player.play(); isPlaying = true }
    }

    func seek(to time: Double) {
        player.seek(to: CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    func seekForward(_ s: Double = 10)  { seek(to: min(currentTime + s, duration)) }
    func seekBackward(_ s: Double = 10) { seek(to: max(currentTime - s, 0)) }
    func toggleFullscreen() { isFullscreen.toggle() }

    func stop() {
        removeTimeObserver()
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
    }

    private func removeTimeObserver() {
        if let obs = timeObserver { player.removeTimeObserver(obs); timeObserver = nil }
    }
}
