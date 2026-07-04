import SwiftUI

@MainActor
final class VideoDetailViewModel: ObservableObject {
    @Published var detail: VideoDetail?
    @Published var relatedVideos: [Video] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private(set) var bvid: String

    init(bvid: String) {
        self.bvid = bvid
    }

    func load() async {
        await load(bvid: bvid)
    }

    func reload(bvid newBvid: String) async {
        bvid = newBvid
        await load(bvid: newBvid)
    }

    private func load(bvid targetBvid: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 并行加载详情 + 相关视频
            async let detailTask: VideoDetail = BiliAPIClient.shared.getWBI(
                BiliAPI.videoInfo,
                params: ["bvid": targetBvid]
            )
            async let relatedTask: [Video] = BiliAPIClient.shared.get(
                BiliAPI.related,
                params: ["bvid": targetBvid]
            )

            let (d, r) = try await (detailTask, relatedTask)
            detail = d
            relatedVideos = r
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
