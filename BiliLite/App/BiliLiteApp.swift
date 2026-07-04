import SwiftUI

@main
struct BiliLiteApp: App {

    init() {
        // 启动时预热 buvid3
        Task {
            _ = await DeviceIdentity.shared.getBuvid3()
        }
        // URLSession 缓存配置
        URLCache.shared.memoryCapacity = 10 * 1024 * 1024   // 10 MB
        URLCache.shared.diskCapacity = 100 * 1024 * 1024    // 100 MB
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)  // B站风暗色主题
                .tint(.pink)                   // B站粉
        }
    }
}
