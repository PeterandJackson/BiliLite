import SwiftUI

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // QR 码
                Group {
                    if let img = vm.qrCodeImage {
                        Image(uiImage: img)
                            .resizable().interpolation(.none)
                            .frame(width: 220, height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pink, lineWidth: 2))
                    } else {
                        ProgressView().scaleEffect(1.5).frame(width: 220, height: 220)
                    }
                }

                Text(vm.loginStatus)
                    .font(.headline).foregroundColor(vm.isLoggedIn ? .green : .secondary)

                if vm.isLoggedIn {
                    HStack {
                        if !vm.userFace.isEmpty {
                            CachedAsyncImage(url: URL(string: vm.userFace))
                                .frame(width: 40, height: 40).clipShape(Circle())
                        }
                        Text(vm.userName).font(.title3.bold())
                    }
                    Button("完成") { dismiss() }
                        .font(.headline).foregroundColor(.white)
                        .padding(.horizontal, 40).padding(.vertical, 12)
                        .background(Color.pink).clipShape(Capsule())
                }

                Spacer()

                // 手动 cookie 输入
                VStack(spacing: 8) {
                    Text("或手动输入 SESSDATA Cookie").font(.caption).foregroundColor(.secondary)
                    TextField("粘贴 SESSDATA 值", text: $vm.sessionCookie)
                        .textFieldStyle(.roundedBorder).padding(.horizontal, 40)
                    Button("手动登录") {
                        if !vm.sessionCookie.isEmpty {
                            UserDefaults.standard.set(vm.sessionCookie, forKey: "bili_sessdata")
                            vm.isLoggedIn = true
                            vm.loginStatus = "Cookie 已保存"
                            vm.userName = "Cookie 用户"
                        }
                    }
                    .font(.subheadline).foregroundColor(.pink)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("登录 B站")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { vm.cancel(); dismiss() }
                }
            }
            .task { await vm.fetchQRCode() }
        }
    }
}
