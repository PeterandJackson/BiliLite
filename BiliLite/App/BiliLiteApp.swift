import SwiftUI
import AVFoundation

@main
struct BiliLiteApp: App {

    init() {
        // 启动时预热 buvid3
        Task {
            _ = await DeviceIdentity.shared.getBuvid3()
        }
        // URLSession 缓存配置
        URLCache.shared.memoryCapacity = 20 * 1024 * 1024   // 20 MB
        URLCache.shared.diskCapacity = 200 * 1024 * 1024    // 200 MB

        // 配置后台/画中画音频
        configureAudioSession()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("[BiliLite] AudioSession config failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .tint(.pink)
        }
    }
}
