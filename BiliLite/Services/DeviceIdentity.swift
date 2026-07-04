import Foundation

/// 设备标识管理：生成 / 持久化 buvid3
actor DeviceIdentity {
    static let shared = DeviceIdentity()

    private let buvid3Key = "bili_buvid3"
    private let buvid4Key = "bili_buvid4"

    /// 获取或生成 buvid3
    func getBuvid3() -> String {
        if let existing = UserDefaults.standard.string(forKey: buvid3Key), !existing.isEmpty {
            return existing
        }
        let new = generateBuvid3()
        UserDefaults.standard.set(new, forKey: buvid3Key)
        return new
    }

    /// 获取或生成 buvid4
    func getBuvid4() -> String {
        if let existing = UserDefaults.standard.string(forKey: buvid4Key), !existing.isEmpty {
            return existing
        }
        let new = generateBuvid4()
        UserDefaults.standard.set(new, forKey: buvid4Key)
        return new
    }

    /// 获取完整 Cookie 字符串
    func getCookieString() async -> String {
        let b3 = await getBuvid3()
        let b4 = await getBuvid4()
        return "buvid3=\(b3); buvid4=\(b4)"
    }

    /// 生成 buvid3: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXinfoc
    private func generateBuvid3() -> String {
        let hex = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let a = String(hex.prefix(8))
        let b = String(hex.dropFirst(8).prefix(4))
        let c = String(hex.dropFirst(12).prefix(4))
        let d = String(hex.dropFirst(16).prefix(4))
        let e = String(hex.dropFirst(20).prefix(11))
        return "\(a)-\(b)-\(c)-\(d)-\(e)infoc"
    }

    /// 生成 buvid4
    private func generateBuvid4() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}

// MARK: - 非 actor 便利方法（调用方可能是非 async 上下文）

extension DeviceIdentity {
    /// 同步获取 buvid3（仅在确定已有值时使用）
    nonisolated func getBuvid3Sync() -> String? {
        UserDefaults.standard.string(forKey: buvid3Key)
    }

    /// 同步获取 cookie 字符串
    nonisolated func getCookieSync() -> String {
        let b3 = UserDefaults.standard.string(forKey: buvid3Key) ?? ""
        let b4 = UserDefaults.standard.string(forKey: buvid4Key) ?? ""
        return "buvid3=\(b3); buvid4=\(b4)"
    }
}
