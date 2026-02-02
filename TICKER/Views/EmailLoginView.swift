import SwiftUI

struct EmailLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var loginId = ""
    @State private var password = ""
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var isFormValid: Bool {
        !loginId.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        ZStack {
            // 배경 (SignupView와 동일하게 통일)
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.08, green: 0.08, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 네비게이션 바
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("이메일 로그인")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 입력 폼
                        VStack(spacing: 20) {
                            inputGroup(title: "이메일", placeholder: "이메일을 입력하세요", text: $loginId)
                            
                            inputGroup(title: "비밀번호", placeholder: "비밀번호를 입력하세요", text: $password, isSecure: true)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.05))
                        )
                        
                        // 로그인 버튼
                        Button(action: handleLogin) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.black)
                                        .padding(.trailing, 8)
                                }
                                Text("로그인")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isFormValid ? Color.green : Color.gray)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(24)
                }
            }
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func inputGroup(title: String, placeholder: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            
            if isSecure {
                SecureField(placeholder, text: text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundStyle(.white)
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundStyle(.white)
            }
        }
    }
    
    private func handleLogin() {
        isLoading = true
        
        Task {
            do {
                let request = LoginRequest(loginId: loginId, password: password)
                try await appState.login(request: request)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    EmailLoginView()
        .environmentObject(AppState())
}
