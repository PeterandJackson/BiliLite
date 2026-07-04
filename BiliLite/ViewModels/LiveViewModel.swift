import SwiftUI
import AVFoundation

/// 直播播放 ViewModel — B站直播流 + 房间列表
@MainActor
final class LiveViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var isLoadingList = false
    @Published var errorMessage: String?
    @Published var roomTitle = ""
    @Published var ownerName = ""
    @Published var onlineCount = 0
    @Published var liveStatus = 0
    @Published var qualityOptions: [LiveQuality] = []
    @Published var danmakuItems: [DanmakuItem] = []
    @Published var rooms: [LiveRoomItem] = []

    /// 加载热门直播房间列表
    func loadRooms() async {
        isLoadingList = true
        do {
            let resp: LiveListResp = try await BiliAPIClient.shared.get("/xlive/web-interface/v2/index/getTopList", params: ["platform": "web"])
            rooms = resp.data.rooms ?? []
        } catch {}
        isLoadingList = false
    }

    /// 加载直播间信息 + 流地址
    func loadRoom(roomId: Int) async {
        isLoading = true; errorMessage = nil

        do {
            // 1. 获取直播间信息
            let roomInfo: LiveRoomResponse = try await BiliAPIClient.shared.get(
                "/xlive/web-room/v1/index/getInfoByRoom",
                params: ["room_id": "\(roomId)"]
            )
            let info = roomInfo.data.room_info
            liveStatus = info.live_status
            roomTitle = info.title ?? "直播间"
            ownerName = roomInfo.data.anchor_info.base_info.uname ?? ""
            onlineCount = info.online ?? 0

            guard liveStatus == 1 else {
                errorMessage = "主播不在直播中"; isLoading = false; return
            }

            // 2. 获取流地址
            let playURL: LivePlayResponse = try await BiliAPIClient.shared.get(
                "/xlive/web-room/v2/index/getRoomPlayInfo",
                params: ["room_id": "\(roomId)", "protocol": "0,1", "format": "0,1,2", "codec": "0,1"]
            )
            guard let firstStream = playURL.data.playurl_info?.playurl?.stream?.first,
                  let firstFormat = firstStream.format?.first,
                  let firstCodec = firstFormat.codec?.first,
                  let baseURL = firstCodec.base_url,
                  let url = URL(string: baseURL)
            else {
                errorMessage = "无法获取直播流"; isLoading = false; return
            }

            // 解析可用质量
            if let acceptQn = firstCodec.accept_qn {
                qualityOptions = acceptQn.map { LiveQuality(qn: $0) }
            }

            setupPlayer(with: url)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func setupPlayer(with url: URL) {
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [
                "Referer": "https://live.bilibili.com",
                "User-Agent": BiliAPI.userAgent
            ]
        ])
        let item = AVPlayerItem(asset: asset)
        if player == nil { player = AVPlayer() }
        player?.replaceCurrentItem(with: item)
        player?.play()
        isPlaying = true
    }

    func togglePlayPause() {
        guard let p = player else { return }
        if p.rate > 0 { p.pause(); isPlaying = false } else { p.play(); isPlaying = true }
    }

    func stop() {
        player?.pause(); player?.replaceCurrentItem(with: nil); isPlaying = false
    }

    /// 加载直播弹幕（B站直播弹幕走 WebSocket — 这里走 HTTP 轮询作为简化版）
    func fetchDanmaku(roomId: Int) async {
        do {
            let items = try await DanmakuParser.shared.fetchDanmaku(cid: roomId)
            danmakuItems = items
        } catch {}
    }
}

struct LiveQuality: Identifiable {
    let id = UUID()
    let qn: Int
    var label: String {
        switch qn {
        case 400: return "蓝光"
        case 250: return "超清"
        case 150: return "高清"
        case 80:  return "流畅"
        default:  return "\(qn)P"
        }
    }
}

// MARK: - 房间列表模型

struct LiveRoomItem: Identifiable, Decodable {
    let roomid: Int; let uid: Int?; let title: String?; let uname: String?; let online: Int?; let cover: String?; let user_cover: String?
    var id: Int { roomid }
}
private struct LiveListResp: Decodable {
    let data: LiveListData; struct LiveListData: Decodable { let rooms: [LiveRoomItem]? }
}

// MARK: - 直播响应模型

private struct LiveRoomResponse: Decodable {
    let data: LiveRoomData
    struct LiveRoomData: Decodable {
        let room_info: LiveRoomInfo
        let anchor_info: LiveAnchorInfo
        struct LiveRoomInfo: Decodable {
            let live_status: Int
            let title: String?
            let online: Int?
        }
        struct LiveAnchorInfo: Decodable {
            let base_info: LiveAnchorBase
            struct LiveAnchorBase: Decodable {
                let uname: String?
            }
        }
    }
}

private struct LivePlayResponse: Decodable {
    let data: LivePlayData
    struct LivePlayData: Decodable {
        let playurl_info: PlayURLInfo?
        struct PlayURLInfo: Decodable {
            let playurl: PlayURL?
            struct PlayURL: Decodable {
                let stream: [StreamInfo]?
                struct StreamInfo: Decodable {
                    let format: [FormatInfo]?
                    struct FormatInfo: Decodable {
                        let codec: [CodecInfo]?
                        struct CodecInfo: Decodable {
                            let base_url: String?
                            let accept_qn: [Int]?
                        }
                    }
                }
            }
        }
    }
}
