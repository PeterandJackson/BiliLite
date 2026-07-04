import SwiftUI

@MainActor
final class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var topComment: Comment?
    @Published var upperName: String?
    @Published var totalCount = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let oid: Int       // 视频 aid
    private var nextCursor = 0
    private var isFirstLoad = true
    private var hasMore = true

    init(oid: Int) {
        self.oid = oid
    }

    func loadComments() async {
        isLoading = true
        errorMessage = nil

        do {
            let replyData: ReplyData = try await BiliAPIClient.shared.getWBI(
                BiliAPI.replyMain,
                params: [
                    "oid": "\(oid)",
                    "type": "1",
                    "mode": "3",
                    "next": "\(nextCursor)",
                    "ps": "20"
                ]
            )

            if isFirstLoad {
                comments = replyData.replies ?? []
                topComment = replyData.top
                upperName = replyData.upper?.name
                totalCount = replyData.page?.acount ?? 0
                isFirstLoad = false
            } else {
                comments.append(contentsOf: replyData.replies ?? [])
            }
            // 使用 API 返回的真正 cursor 值，对比已加载数量与总数判断 hasMore
            if let newCursor = replyData.page?.num {
                nextCursor = newCursor
                let total = replyData.page?.acount ?? 0
                hasMore = comments.count < total
            } else {
                hasMore = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMoreIfNeeded(current comment: Comment) async {
        guard hasMore, !isLoading else { return }
        if let index = comments.firstIndex(where: { $0.id == comment.id }),
           index >= comments.count - 3 {
            await loadComments()
        }
    }
}
