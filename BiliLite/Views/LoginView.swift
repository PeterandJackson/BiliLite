import SwiftUI

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 选项卡
                Picker("", selection: $vm.method) {
                    Text("QR码").tag(LoginViewModel.LoginMethod.qr)
                    Text("网页登录").tag(LoginViewModel.LoginMethod.web)
                }
                .pickerStyle(.segmented).padding()

                // 内容
                if vm.method == .qr {
                    ScrollView { qrTab }
                } else {
                    WebLoginView(vm: vm)
                }

                // 状态
                if !vm.loginStatus.isEmpty {
                    Text(vm.loginStatus).font(.caption).foregroundColor(vm.isLoggedIn ? .green : .orange)
                        .padding(.bottom, 4)
                }
                if vm.isLoggedIn {
                    HStack(spacing: 8) {
                        if !vm.userFace.isEmpty, let u = URL(string: vm.userFace) {
                            CachedAsyncImage(url: u).frame(width: 32, height: 32).clipShape(Circle())
                        }
                        Text(vm.userName).font(.headline)
                        Button("完成") { dismiss() }.font(.headline).foregroundColor(.white)
                            .padding(.horizontal, 24).padding(.vertical, 8).background(Color.pink).clipShape(Capsule())
                    }.padding(.bottom, 8)
                }
            }
            .navigationTitle("登录 B站").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { vm.cancel(); dismiss() } } }
            .task { await vm.fetchQRCode() }
        }
    }

    // MARK: - QR
    private var qrTab: some View {
        VStack(spacing: 16) {
            if let img = vm.qrCodeImage { Image(uiImage: img).resizable().interpolation(.none).frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pink, lineWidth: 2)) }
            else { ProgressView().frame(width: 200, height: 200) }
            Button("刷新二维码") { Task { await vm.fetchQRCode() } }.font(.caption).foregroundColor(.pink)
        }.padding(.top, 24)
    }
}
