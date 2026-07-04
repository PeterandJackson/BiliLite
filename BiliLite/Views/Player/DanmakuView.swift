import SwiftUI

/// 弹幕覆盖层 — 在视频播放器上方
struct DanmakuView: View {
    let items: [DanmakuItem]
    let currentTime: Double

    private let rowHeight: CGFloat = 28
    private let rows = 8

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(visibleItems) { item in
                    danmakuLabel(for: item, width: geo.size.width)
                        .position(danmakuPosition(for: item, width: geo.size.width, height: geo.size.height))
                }
            }
            .clipped()
        }
    }

    /// 当前屏幕上可见的弹幕
    private var visibleItems: [DanmakuItem] {
        items.filter { abs($0.time - currentTime) < 5.0 }
    }

    @ViewBuilder
    private func danmakuLabel(for item: DanmakuItem, width: CGFloat) -> some View {
        let isScrolling = item.mode == 1
        Text(item.text)
            .font(.system(size: min(item.fontSize * 0.8, 22)))
            .foregroundColor(Color(uiColor: danmakuColor(item.color)))
            .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
            .lineLimit(1)
            .fixedSize()
    }

    private func danmakuPosition(for item: DanmakuItem, width: CGFloat, height: CGFloat) -> CGPoint {
        let y = CGFloat(abs(item.text.hashValue) % rows) * rowHeight + rowHeight / 2 + 4
        if item.mode == 1 {
            // 滚动弹幕：从右到左
            let elapsed = currentTime - item.time
            let speed: CGFloat = 120  // px/s
            let x = width - elapsed * speed + width * 0.3
            return CGPoint(x: x, y: y)
        } else if item.mode == 5 {
            // 顶端固定
            return CGPoint(x: width / 2, y: y)
        } else {
            // 底端固定
            return CGPoint(x: width / 2, y: height - rowHeight * 2)
        }
    }

    private func danmakuColor(_ dec: UInt32) -> UIColor {
        let r = CGFloat((dec >> 16) & 0xFF) / 255.0
        let g = CGFloat((dec >> 8) & 0xFF) / 255.0
        let b = CGFloat(dec & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}
