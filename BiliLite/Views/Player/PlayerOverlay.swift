import SwiftUI

/// 自定义播放器覆盖层（进度条、手势调节亮度/音量）
struct PlayerOverlay: View {
    @ObservedObject var viewModel: PlayerViewModel
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 点击区域 → 显示/隐藏控制
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showControls.toggle()
                        if showControls {
                            autoHideControls()
                        }
                    }

                if showControls {
                    // 底部控制栏
                    VStack {
                        Spacer()
                        controlsBar
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showControls)
                }
            }
        }
        .onAppear { autoHideControls() }
    }

    // MARK: - 控制栏

    private var controlsBar: some View {
        VStack(spacing: 4) {
            // 进度条
            Slider(
                value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.seek(to: $0) }
                ),
                in: 0...max(viewModel.duration, 1)
            )
            .tint(.pink)

            // 时间 + 按钮
            HStack {
                Text(viewModel.currentTime.durationFormatted)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white)

                Spacer()

                Button(action: { viewModel.seekBackward() }) {
                    Image(systemName: "gobackward.10")
                        .font(.title3)
                }

                Button(action: { viewModel.togglePlayPause() }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 36)
                }

                Button(action: { viewModel.seekForward() }) {
                    Image(systemName: "goforward.10")
                        .font(.title3)
                }

                Spacer()

                Text(viewModel.duration.durationFormatted)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white)
            }
            .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func autoHideControls() {
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
}
