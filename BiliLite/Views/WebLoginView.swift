import SwiftUI
import WebKit

// MARK: - WKWebView 封装（用于 B站网页登录）

struct WebLoginView: View {
    @ObservedObject var vm: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 顶部提示
            HStack {
                Text("请在网页中登录你的 B站 账号")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("完成") {
                    vm.extractCookiesFromWebView { _ in
                        dismiss()
                    }
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.pink)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // WebView
            BiliWebView(urlString: "https://passport.bilibili.com/login", viewModel: vm)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - UIViewRepresentable WKWebView

private struct BiliWebView: UIViewRepresentable {
    let urlString: String
    @ObservedObject var viewModel: LoginViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // 使用默认的数据存储（与 Safari 隔离，但能保存 cookie）
        config.websiteDataStore = .default()

        // 注入 User-Agent 模拟移动端
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1"
        wv.navigationDelegate = context.coordinator

        if let url = URL(string: urlString) {
            wv.load(URLRequest(url: url))
        }

        viewModel.webView = wv
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Coordinator: Navigation Delegate

    class Coordinator: NSObject, WKNavigationDelegate {
        weak var viewModel: LoginViewModel?

        init(viewModel: LoginViewModel) {
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // 允许所有导航
            decisionHandler(.allow)

            // 检测是否跳转到了 bilibili.com 主站（说明登录成功）
            if let host = navigationAction.request.url?.host,
               host.contains("bilibili.com"),
               !host.contains("passport.bilibili.com") {
                viewModel?.navigatedAwayFromPassport = true
            }
        }
    }
}
