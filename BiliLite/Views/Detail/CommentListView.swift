import SwiftUI

/// 评论区
struct CommentListView: View {
    let oid: Int
    let upperName: String

    @StateObject private var viewModel: CommentViewModel
    @State private var commentText = ""
    @State private var isSending = false
    @State private var showSendError = false
    @FocusState private var isFocused: Bool

    init(oid: Int, upperName: String) {
        self.oid = oid
        self.upperName = upperName
        _viewModel = StateObject(wrappedValue: CommentViewModel(oid: oid))
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                // UP主标签 + 置顶评论
                if let top = viewModel.topComment {
                    Section {
                        commentRow(top, isTop: true)
                    } header: {
                        HStack {
                            Image(systemName: "pin.fill")
                            Text("UP主置顶")
                        }
                    }
                } else if let name = viewModel.upperName {
                    Section {
                        HStack {
                            Image(systemName: "person.circle")
                            Text(name)
                            Text("· UP主")
                                .foregroundColor(.pink)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }

                // 评论列表
                Section {
                    if viewModel.comments.isEmpty && !viewModel.isLoading {
                        Text("暂无评论")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }

                    ForEach(viewModel.comments) { comment in
                        commentRow(comment, isTop: false)
                            .task {
                                await viewModel.loadMoreIfNeeded(current: comment)
                            }
                    }

                    if viewModel.isLoading {
                        LoadMoreView()
                            .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("评论 (\(viewModel.totalCount))")
                }
            }
            // 底部发送区
            sendBar
        }
        .navigationTitle("评论")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadComments()
        }
        .refreshable {
            await viewModel.loadComments()
        }
        .alert("发送失败", isPresented: $showSendError) {
            Button("好", role: .cancel) {}
        } message: {
            Text("请先登录 B站 账号")
        }
    }

    // MARK: - 发送评论
    private var sendBar: some View {
        HStack(spacing: 8) {
            TextField("发一条友善的评论…", text: $commentText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .focused($isFocused)
                .lineLimit(1...4)
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if isSending {
                ProgressView().scaleEffect(0.8)
            } else {
                Button {
                    Task { await sendComment() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(commentText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .pink)
                        .font(.title3)
                }
                .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(Divider().background(Color(.separator)), alignment: .top)
    }

    private func sendComment() async {
        let text = commentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        guard KeychainHelper.read(key: "bili_sessdata")?.isEmpty == false else {
            showSendError = true; return
        }
        isSending = true
        do {
            try await BiliAPIClient.shared.postAction(BiliAPI.sendComment, params: [
                "oid": "\(oid)", "type": "1", "message": text, "plat": "1"
            ])
            commentText = ""
            isFocused = false
            // 刷新评论列表
            await viewModel.loadComments()
        } catch {
            // 静默处理
        }
        isSending = false
    }

    // MARK: - 单条评论

    @ViewBuilder
    private func commentRow(_ comment: Comment, isTop: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 用户信息行
            HStack(spacing: 8) {
                CachedAsyncImage(url: comment.member.avatarURL)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())

                Text(comment.member.uname)
                    .font(.subheadline.bold())

                if let level = comment.member.levelInfo?.currentLevel {
                    Text("Lv\(level)")
                        .font(.system(size: 10))
                        .foregroundColor(.pink)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.pink.opacity(0.15))
                        .clipShape(Capsule())
                }

                Spacer()

                Text(comment.ctime.relativeDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 2) {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 10))
                    Text(comment.like > 0 ? "\(comment.like)" : "")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }

            // 评论文本
            Text(comment.content.message)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            // 嵌套回复（最多展示3条）
            if let replies = comment.replies, !replies.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(replies.prefix(3)) { reply in
                        HStack(alignment: .top, spacing: 4) {
                            Text(reply.member.uname)
                                .foregroundColor(.pink)
                            Text(": ")
                                .foregroundColor(.secondary)
                            Text(reply.content.message)
                                .foregroundColor(.primary)
                        }
                        .font(.caption)
                        .lineLimit(2)
                    }

                    if comment.rcount > 3 {
                        Text("共 \(comment.rcount) 条回复 >")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.leading, 36)
            }
        }
        .padding(.vertical, 4)
    }
}
