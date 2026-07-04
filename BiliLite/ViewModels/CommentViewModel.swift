import SwiftUI

@MainActor
final class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var topComment: Comment?
    @Published var upperName: String?
    @Published var totalCount = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let oid: Int
    private var nextCursor = 0
    private var hasMore = true

    init(oid: Int) {
        self.oid = oid
    }

    func loadComments() async {
        // Refresh: reset pagination
        nextCursor = 0; hasMore = true; comments = []
        await loadPage()
    }

    private func loadPage() async {
        guard !isLoading else { return }
        isLoading = true; errorMessage = nil

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

            if nextCursor == 0 {
                topComment = replyData.top
                upperName = replyData.upper?.name
                totalCount = replyData.page?.acount ?? 0
            }

            let newReplies = replyData.replies ?? []
            comments.append(contentsOf: newReplies)

            // B站 reply API: page.num 是当前页码，下一页 = num + 1
            // 当返回数据 < ps 时说明没有更多
            if let num = replyData.page?.num, newReplies.count >= 20 {
                nextCursor = num + 1
                hasMore = comments.count < totalCount
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
            await loadPage()
        }
    }
}
