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
                    Text("密码").tag(LoginViewModel.LoginMethod.password)
                    Text("短信").tag(LoginViewModel.LoginMethod.sms)
                }
                .pickerStyle(.segmented).padding()

                // 内容
                ScrollView {
                    switch vm.method {
                    case .qr: qrTab
                    case .password: passwordTab
                    case .sms: smsTab
                    }
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

    // MARK: - 密码
    private var passwordTab: some View {
        VStack(spacing: 12) {
            TextField("手机号/邮箱", text: $vm.phoneOrUser).textContentType(.username)
                .textFieldStyle(.roundedBorder).padding(.horizontal, 24)
            SecureField("密码", text: $vm.password).textFieldStyle(.roundedBorder).padding(.horizontal, 24)
            Button(action: { Task { await vm.passwordLogin() } }) {
                Text("登录").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity)
                    .padding(.vertical, 12).background(Color.pink).clipShape(Capsule())
            }.padding(.horizontal, 40).disabled(vm.phoneOrUser.isEmpty || vm.password.isEmpty)
        }.padding(.top, 24)
    }

    // MARK: - 短信
    private var smsTab: some View {
        VStack(spacing: 12) {
            HStack {
                Text("+86").font(.headline).padding(.leading, 24)
                TextField("手机号", text: $vm.smsPhone).keyboardType(.phonePad).textFieldStyle(.roundedBorder)
            }
            HStack {
                TextField("验证码", text: $vm.smsCode).keyboardType(.numberPad).textFieldStyle(.roundedBorder).padding(.leading, 24)
                Button(action: { Task { await vm.sendSMS() } }) {
                    Text(vm.smsCountdown > 0 ? "\(vm.smsCountdown)s" : "获取验证码")
                        .font(.caption).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8)
                        .background(vm.smsReady ? Color.pink : Color.gray).clipShape(Capsule())
                }.disabled(!vm.smsReady).padding(.trailing, 24)
            }
            Button(action: { Task { await vm.smsLogin() } }) {
                Text("验证并登录").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity)
                    .padding(.vertical, 12).background(Color.pink).clipShape(Capsule())
            }.padding(.horizontal, 40).disabled(vm.smsCode.isEmpty)
        }.padding(.top, 24)
    }
}
