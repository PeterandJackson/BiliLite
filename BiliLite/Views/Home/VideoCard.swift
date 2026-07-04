import SwiftUI

/// 视频卡片组件 — 封面、标题、UP主、数据
struct VideoCard: View {
    let video: Video

    @State private var coverFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面区域（16:9 比例 + 时长标签）
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(url: video.coverURL)
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // 时长标签
                Text(video.duration.durationFormatted)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(6)
            }

            // 标题（最多两行）
            Text(video.title)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            // UP主 + 播放量
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .font(.caption)
                    Text(video.owner.name)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "play.rectangle")
                        .font(.caption)
                    Text(video.stat.view.biliFormatted)
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                if video.stat.danmaku > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "text.bubble")
                            .font(.caption)
                        Text(video.stat.danmaku.biliFormatted)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .drawingGroup()  // 减少 SwiftUI 重绘开销
    }
}
