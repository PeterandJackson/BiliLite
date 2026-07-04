import SwiftUI

/// 番剧页面 — 时间表 + 热门推荐
struct BangumiView: View {
    @StateObject private var viewModel = BangumiViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading && viewModel.days.isEmpty {
                    LoadingView(message: "加载番剧…").padding(.top, 60)
                } else if let e = viewModel.errorMessage, viewModel.days.isEmpty {
                    ErrorBanner(message: e) { Task { await viewModel.load() } }.padding(.top, 8)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("📅 新番时间表").font(.headline).padding(.horizontal)

                        ForEach(viewModel.days, id: \.dayOfWeek) { day in
                            daySection(day)
                        }

                        if !viewModel.hotSeasons.isEmpty {
                            Text("🔥 热门番剧").font(.headline).padding(.horizontal).padding(.top, 8)
                            hotSection
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("番剧")
            .background(Color(.systemGroupedBackground))
            .task { if viewModel.days.isEmpty { await viewModel.load() } }
            .refreshable { await viewModel.refresh() }
        }
    }

    @ViewBuilder
    private func daySection(_ day: BangumiDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(weekdayName(day.dayOfWeek ?? 0))
                .font(.subheadline.bold())
                .foregroundColor(isToday(day.dayOfWeek) ? .pink : .primary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(day.seasons ?? []) { season in
                        VStack(alignment: .leading, spacing: 4) {
                            CachedAsyncImage(url: URL(string: (season.cover ?? "").replacingOccurrences(of: "http://", with: "https://")))
                                .frame(width: 120, height: 160).clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(season.title ?? "").font(.caption).lineLimit(2).frame(width: 120, alignment: .leading)
                            if let ep = season.pubIndex { Text(ep).font(.caption2).foregroundColor(.pink) }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var hotSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(viewModel.hotSeasons) { season in
                VStack(alignment: .leading, spacing: 4) {
                    CachedAsyncImage(url: URL(string: (season.cover ?? "").replacingOccurrences(of: "http://", with: "https://")))
                        .frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 8))
                    Text(season.title ?? "").font(.caption).lineLimit(2)
                }
            }
        }.padding(.horizontal)
    }

    private func weekdayName(_ dow: Int) -> String {
        let names = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        return dow < names.count ? names[dow] : "未知"
    }

    private func isToday(_ dow: Int?) -> Bool {
        let cal = Calendar.current; let today = cal.component(.weekday, from: Date())
        // 中国的周一=1 → 周日=7；Calendar 周日=1 → 周六=7
        let c = (today + 5) % 7 + 1
        return dow == c
    }
}

// MARK: - ViewModel

@MainActor
final class BangumiViewModel: ObservableObject {
    @Published var days: [BangumiDay] = []
    @Published var hotSeasons: [BangumiSeason] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true; errorMessage = nil
        do {
            async let timeline: BangumiTimelineResp = BiliAPIClient.shared.get(BiliAPI.bangumiTimeline)
            async let hot: BiliHotBangumiResp = BiliAPIClient.shared.get(BiliAPI.bangumiHot)
            let (t, h) = try await (timeline, hot)
            days = t.result ?? []
            hotSeasons = h.list?.prefix(15).map { BangumiSeason(seasonId: $0.seasonId, title: $0.title, cover: $0.cover, url: $0.url, pubIndex: $0.newEp?.indexShow) } ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refresh() async { await load() }
}

private struct BiliHotBangumiResp: Decodable {
    let list: [HotBangumiItem]?
    struct HotBangumiItem: Decodable {
        let seasonId: Int?; let title: String?; let cover: String?; let url: String?
        let newEp: NewEp?; let badge: String?
        struct NewEp: Decodable { let indexShow: String? }
    }
}
