import SwiftUI

/// 弹幕视图 — 使用 ZStack + ForEach + position 简单绘制，无电池消耗
struct DanmakuView: View {
    let items: [DanmakuItem]
    let currentTime: Double

    var body: some View {
        GeometryReader { geo in
            let rowH = geo.size.height / 10.0
            let filtered = items
                .filter { abs($0.time - currentTime) < 9.0 }
                .prefix(20)

            ZStack {
                ForEach(Array(filtered)) { item in
                    let y = CGFloat(abs(item.text.hashValue) % 10) * rowH + rowH * 0.5
                    let elapsed = currentTime - item.time
                    let x: CGFloat = {
                        switch item.mode {
                        case 1:  // 滚动
                            return geo.size.width - elapsed * 120 + geo.size.width * 0.3
                        case 5:  // 顶部
                            return geo.size.width / 2
                        default:  // 底部
                            return geo.size.width / 2
                        }
                    }()

                    Text(item.text)
                        .font(.system(size: min(item.fontSize * 0.65, 18)))
                        .lineLimit(1)
                        .foregroundColor(Color(danmakuColor(item.color)))
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                        .position(x: x, y: y)
                }
            }
        }
    }

    private func danmakuColor(_ dec: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((dec >> 16) & 0xFF) / 255.0,
            green: CGFloat((dec >> 8) & 0xFF) / 255.0,
            blue: CGFloat(dec & 0xFF) / 255.0,
            alpha: 1
        )
    }
}
