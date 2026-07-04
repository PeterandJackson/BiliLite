import UIKit
import Foundation

/// 图片缓存管理器：NSCache（内存 50MB）+ FileManager（磁盘 200MB）+ 自动降采样
actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDir: URL
    private let maxDiskSize: Int = 200 * 1024 * 1024  // 200 MB
    private let ttl: TimeInterval = 7 * 86400          // 7 天
    private let targetWidth: CGFloat = 300              // 降采样宽度

    private init() {
        memoryCache.countLimit = 200
        memoryCache.totalCostLimit = 50 * 1024 * 1024   // 50 MB

        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDir = caches.appendingPathComponent("BiliImageCache")
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        // 后台清理过期文件
        Task.detached(priority: .background) { [weak self] in
            await self?.cleanupIfNeeded()
        }
    }

    // MARK: - 获取图片

    func image(for url: URL) -> UIImage? {
        let key = cacheKey(url)

        // 1. 内存
        if let img = memoryCache.object(forKey: key as NSString) {
            return img
        }

        // 2. 磁盘
        let fileURL = cacheDir.appendingPathComponent(key)
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        // 更新时间戳
        try? (fileURL as NSURL).setResourceValue(Date(), forKey: .contentModificationDateKey)

        // 降采样
        guard let img = downsample(data: data, to: targetWidth) else { return nil }

        // 回填内存
        let cost = Int(img.size.width * img.size.height * 4)
        memoryCache.setObject(img, forKey: key as NSString, cost: cost)

        return img
    }

    // MARK: - 存图片

    func store(image: UIImage, for url: URL) {
        let key = cacheKey(url)

        // 内存
        let cost = Int(image.size.width * image.size.height * 4)
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)

        // 磁盘（异步）
        let fileURL = cacheDir.appendingPathComponent(key)
        Task.detached(priority: .background) { [fileURL, fileManager] in
            if let data = image.jpegData(compressionQuality: 0.85) {
                try? data.write(to: fileURL)
            }
        }
    }

    func store(data: Data, for url: URL) {
        let key = cacheKey(url)
        guard let img = downsample(data: data, to: targetWidth) else { return }

        let cost = Int(img.size.width * img.size.height * 4)
        memoryCache.setObject(img, forKey: key as NSString, cost: cost)

        let fileURL = cacheDir.appendingPathComponent(key)
        Task.detached(priority: .background) { [fileURL, fileManager] in
            try? data.write(to: fileURL)
        }
    }

    // MARK: - 清理

    func clearMemory() {
        memoryCache.removeAllObjects()
    }

    private func cleanupIfNeeded() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDir,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }

        var totalSize = 0
        var oldFiles: [(URL, Int, Date)] = []

        for file in files {
            guard let attrs = try? fileManager.attributesOfItem(atPath: file.path),
                  let size = attrs[FileAttributeKey.size] as? Int,
                  let date = attrs[FileAttributeKey.modificationDate] as? Date else { continue }
            totalSize += size
            oldFiles.append((file, size, date))
        }

        // 过期清理
        let cutoff = Date().addingTimeInterval(-ttl)
        for (file, _, date) in oldFiles where date < cutoff {
            try? fileManager.removeItem(at: file)
        }

        // 超量清理（LRU）
        if totalSize > maxDiskSize {
            oldFiles.sort { $0.2 < $1.2 }  // 最旧在前
            for (file, size, _) in oldFiles {
                guard totalSize > maxDiskSize else { break }
                try? fileManager.removeItem(at: file)
                totalSize -= size
            }
        }
    }

    // MARK: - 内部

    private func cacheKey(_ url: URL) -> String {
        let key = url.absoluteString.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .prefix(64)
        return String(key)
    }

    /// 降采样图片到目标宽度
    private func downsample(data: Data, to width: CGFloat) -> UIImage? {
        let maxPixel = width * 3.0  // @3x for iPhone X
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cg)
    }
}
