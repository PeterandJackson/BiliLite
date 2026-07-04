import SwiftUI

/// 带缓存 + 降采样的异步图片组件
struct CachedAsyncImage: View {
    let url: URL?
    var placeholder: Image = Image(systemName: "photo")

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ZStack {
                    Color(.systemGray6)
                    ProgressView()
                        .scaleEffect(0.7)
                }
            } else {
                ZStack {
                    Color(.systemGray6)
                    placeholder
                        .foregroundColor(.gray)
                }
            }
        }
        .task(id: url?.absoluteString) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else {
            isLoading = false
            return
        }

        // 先查缓存
        if let cached = await ImageCache.shared.image(for: url) {
            image = cached
            isLoading = false
            return
        }

        // 下载
        do {
            let data = try await BiliAPIClient.shared.getData(url)
            await ImageCache.shared.store(data: data, for: url)
            if let cached = await ImageCache.shared.image(for: url) {
                image = cached
            }
        } catch {
            // 下载失败，静默处理
        }

        isLoading = false
    }
}
