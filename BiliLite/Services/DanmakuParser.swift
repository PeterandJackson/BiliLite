import Foundation

/// 弹幕条目
struct DanmakuItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let time: Double       // 出现时间（秒）
    let mode: Int          // 1=滚动 4=底端 5=顶端
    let fontSize: Double
    let color: UInt32     // 10进制颜色
    let sendTime: Int

    static func == (lhs: DanmakuItem, rhs: DanmakuItem) -> Bool { lhs.id == rhs.id }
}

/// B站弹幕 XML → DanmakuItem 数组
actor DanmakuParser {
    static let shared = DanmakuParser()
    private var cache: [Int: [DanmakuItem]] = [:]

    /// 获取视频弹幕（按 cid 缓存）
    func fetchDanmaku(cid: Int) async throws -> [DanmakuItem] {
        if let cached = cache[cid] { return cached }

        let url = URL(string: "https://api.bilibili.com/x/v1/dm/list.so?oid=\(cid)")!
        var req = URLRequest(url: url)
        req.setValue(BiliAPI.userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue(BiliAPI.referer, forHTTPHeaderField: "Referer")

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let xml = String(data: data, encoding: .utf8) else { return [] }

        let items = parseXML(xml)
        cache[cid] = items
        return items
    }

    /// 简单 XML 解析 — 提取所有 <d p="...">text</d>
    nonisolated private func parseXML(_ xml: String) -> [DanmakuItem] {
        var items: [DanmakuItem] = []
        let pattern = #"<d p="([^"]+)"[^>]*>([^<]+)</d>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let nsRange = NSRange(xml.startIndex..<xml.endIndex, in: xml)
        for match in regex.matches(in: xml, range: nsRange) {
            guard let pRange = Range(match.range(at: 1), in: xml),
                  let tRange = Range(match.range(at: 2), in: xml) else { continue }
            let attrs = String(xml[pRange]).split(separator: ",")
            let text = String(xml[tRange])
            guard attrs.count >= 7 else { continue }
            if let time = Double(attrs[0]),
               let mode = Int(attrs[1]),
               let fontSize = Double(attrs[2]),
               let color = UInt32(attrs[3]),
               let sendTime = Int(attrs[4]) {
                items.append(DanmakuItem(text: text, time: time, mode: mode, fontSize: fontSize, color: color, sendTime: sendTime))
            }
        }
        // 过滤太长的弹幕
        return items.filter { $0.text.count < 60 }
    }
}
