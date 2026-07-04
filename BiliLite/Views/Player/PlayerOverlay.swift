import SwiftUI

struct PlayerOverlay: View {
    @ObservedObject var viewModel: PlayerViewModel
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?
    @State private var showQualityPicker = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 点击切换控制
                Color.clear.contentShape(Rectangle())
                    .onTapGesture { toggleControls() }

                if showControls {
                    // 顶部栏
                    VStack {
                        topBar.padding(.horizontal, 12).padding(.top, 4)
                        Spacer()
                        bottomBar.padding(.horizontal, 16).padding(.bottom, 8)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: showControls)
                }

                // 质量选择器
                if showQualityPicker {
                    qualityPicker(in: geo.size)
                }
            }
        }
        .onAppear { autoHideControls() }
        .onDisappear { hideTask?.cancel() }
    }

    // MARK: - 顶部栏
    private var topBar: some View {
        HStack {
            Image(systemName: "chevron.down")
                .font(.title3).foregroundColor(.white).padding(8)
                .contentShape(Rectangle())
                .onTapGesture { /* 关闭 — 由父视图处理 */ }
            Spacer()
            Button(action: { showQualityPicker.toggle() }) {
                Text(viewModel.currentQuality.label)
                    .font(.caption.bold()).foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.white.opacity(0.2)).clipShape(Capsule())
            }
            Button(action: { viewModel.toggleFullscreen() }) {
                Image(systemName: viewModel.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.title3).foregroundColor(.white).padding(8)
            }
        }
        .background(LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom))
    }

    // MARK: - 底部控制栏
    private var bottomBar: some View {
        VStack(spacing: 4) {
            Slider(value: Binding(get: { viewModel.currentTime }, set: { viewModel.seek(to: $0) }),
                   in: 0...max(viewModel.duration, 1))
                .tint(.pink)
            HStack {
                Text(viewModel.currentTime.durationFormatted).font(.caption.monospacedDigit()).foregroundColor(.white)
                Spacer()
                Button(action: { viewModel.seekBackward() }) {
                    Image(systemName: "gobackward.10").font(.title3).foregroundColor(.white)
                }
                Button(action: { viewModel.togglePlayPause() }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title).foregroundColor(.white).frame(width: 40)
                }
                Button(action: { viewModel.seekForward() }) {
                    Image(systemName: "goforward.10").font(.title3).foregroundColor(.white)
                }
                Spacer()
                Text(viewModel.duration.durationFormatted).font(.caption.monospacedDigit()).foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom))
    }

    // MARK: - 质量选择
    private func qualityPicker(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            ForEach(viewModel.availableQualities, id: \.rawValue) { q in
                Button(action: {
                    showQualityPicker = false
                    Task { await viewModel.switchQuality(q) }
                }) {
                    HStack {
                        Text(q.label).foregroundColor(.white)
                        Spacer()
                        if q == viewModel.currentQuality { Image(systemName: "checkmark").foregroundColor(.pink) }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                }
                Divider().background(Color.white.opacity(0.2))
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(width: min(size.width * 0.5, 200))
        .position(x: size.width - 100, y: 80)
    }

    private func toggleControls() { showControls.toggle(); if showControls { autoHideControls() } }
    private func autoHideControls() { hideTask?.cancel(); hideTask = Task { try? await Task.sleep(nanoseconds: 3_000_000_000); withAnimation { showControls = false } } }
}
