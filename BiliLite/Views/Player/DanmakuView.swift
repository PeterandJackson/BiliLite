import SwiftUI

/// Canvas 批量绘制弹幕 — 丝滑无卡顿
struct DanmakuView: View {
    let items: [DanmakuItem]
    let currentTime: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let filtered = items.filter { abs($0.time - currentTime) < 9.0 }.prefix(30)
                let rowH = size.height / 10.0
                for item in filtered {
                    let y = CGFloat(abs(item.text.hashValue) % 10) * rowH + rowH * 0.5
                    let elapsed = currentTime - item.time
                    var x: CGFloat
                    switch item.mode {
                    case 1: // 滚动
                        x = size.width - elapsed * 120 + size.width * 0.3
                    case 5: // 顶部
                        x = size.width / 2
                    default: // 底部
                        x = size.width / 2
                    }
                    let color = danmakuColor(item.color)
                    let font = UIFont.systemFont(ofSize: min(item.fontSize * 0.65, 18))
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font, .foregroundColor: color,
                        .strokeColor: UIColor.black, .strokeWidth: -2.0
                    ]
                    let str = AttributedString(NSAttributedString(string: item.text, attributes: attrs))
                    let textSize = ctx.resolve(Text(str).font(.system(size: min(item.fontSize * 0.65, 18))))
                    ctx.draw(Text(str), at: CGPoint(x: x - textSize.measure(in: size).width / 2, y: y - textSize.measure(in: size).height / 2))
                }
            }
        }
    }

    private func danmakuColor(_ dec: UInt32) -> UIColor {
        UIColor(red: CGFloat((dec >> 16) & 0xFF) / 255.0, green: CGFloat((dec >> 8) & 0xFF) / 255.0, blue: CGFloat(dec & 0xFF) / 255.0, alpha: 1)
    }
}
