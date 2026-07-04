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
    @Published var autoPlayNext = false
    var onVideoEnded: (() -> Void)?  // 自动联播回调

    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    var currentBvid = ""
    var currentCid = 0

    func play(bvid: String, cid: Int, quality: BiliQuality = .p480) async {
        let savedTime = currentTime
        isLoading = true; errorMessage = nil
        currentBvid = bvid; currentCid = cid; currentQuality = quality
        do {
            let stream: VideoStream = try await BiliAPIClient.shared.getWBI(
                BiliAPI.playURL,
                params: ["bvid": bvid, "cid": "\(cid)", "qn": "\(quality.rawValue)", "fnval": "1", "fnver": "0", "fourk": "0"]
            )
            guard let url = stream.firstURL else { errorMessage = "无法获取播放地址"; isLoading = false; return }
            if let a = stream.acceptQuality { availableQualities = a.compactMap(BiliQuality.init) }
            setupPlayer(with: url, startTime: savedTime > 1 ? savedTime : nil)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func switchQuality(_ q: BiliQuality) async { currentQuality = q; await play(bvid: currentBvid, cid: currentCid, quality: q) }

    private func setupPlayer(with url: URL, startTime: Double? = nil) {
        removeTimeObserver()
        if let o = endObserver { NotificationCenter.default.removeObserver(o); endObserver = nil }
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["Referer": BiliAPI.referer, "User-Agent": BiliAPI.userAgent]])
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        if let start = startTime {
            player.seek(to: CMTime(seconds: start, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        }
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] t in
            guard let s = self else { return }
            s.currentTime = t.seconds
            if let d = s.player.currentItem?.duration, d.isNumeric { s.duration = d.seconds }
        }
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            guard let s = self else { return }
            s.isPlaying = false
            if s.autoPlayNext { s.onVideoEnded?() }
        }
        player.play(); isPlaying = true
    }

    func togglePlayPause() { if player.rate > 0 { player.pause(); isPlaying = false } else { player.play(); isPlaying = true } }
    func seek(to t: Double) { player.seek(to: CMTime(seconds: t, preferredTimescale: CMTimeScale(NSEC_PER_SEC))) }
    func seekForward(_ s: Double = 10) { seek(to: min(currentTime + s, duration)) }
    func seekBackward(_ s: Double = 10) { seek(to: max(currentTime - s, 0)) }
    func toggleFullscreen() { isFullscreen.toggle() }

    func stop() {
        removeTimeObserver()
        if let o = endObserver { NotificationCenter.default.removeObserver(o); endObserver = nil }
        player.pause(); player.replaceCurrentItem(with: nil); isPlaying = false
    }

    private func removeTimeObserver() { if let o = timeObserver { player.removeTimeObserver(o); timeObserver = nil } }
}
