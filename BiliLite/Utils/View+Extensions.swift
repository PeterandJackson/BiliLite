import SwiftUI

// MARK: - 常用 View Modifier

extension View {
    /// 应用标准卡片样式
    func cardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    /// 水平填充，左对齐
    func leadingFill() -> some View {
        self.frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 数字格式化

extension Int {
    /// 万/亿 简化显示
    var biliFormatted: String {
        if self >= 100_000_000 {
            return String(format: "%.1f亿", Double(self) / 100_000_000.0)
        }
        if self >= 10_000 {
            return String(format: "%.1f万", Double(self) / 10_000.0)
        }
        return "\(self)"
    }
}

// MARK: - 时长格式化

extension Int {
    /// 秒数 → mm:ss 或 hh:mm:ss
    var durationFormatted: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        let s = self % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

extension Double {
    /// 秒数 → mm:ss 或 hh:mm:ss
    var durationFormatted: String {
        Int(self).durationFormatted
    }
}

// MARK: - 时间戳格式化

extension Int {
    /// Unix时间戳 → "x天前" / "yyyy-MM-dd"
    var relativeDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(self))
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 3600 { return "\(max(1, Int(interval / 60)))分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600))小时前" }
        if interval < 604800 { return "\(Int(interval / 86400))天前" }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
