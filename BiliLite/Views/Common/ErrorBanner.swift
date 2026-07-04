import SwiftUI

/// 错误提示 Banner
struct ErrorBanner: View {
    let message: String
    var onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let retry = onRetry {
                Spacer()
                Button("重试", action: retry)
                    .font(.subheadline.bold())
                    .foregroundColor(.pink)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}
