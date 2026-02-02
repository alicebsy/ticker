import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var loginId = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var name = ""
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var isFormValid: Bool {
        !loginId.isEmpty && !password.isEmpty && !name.isEmpty && password == passwordConfirm
    }
    
    var body: some View {
        ZStack {
            // 배경 (LoginView와 동일하게)
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
                    Text("회원가입")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    // 균형을 위한 빈 공간
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 입력 폼
                        VStack(spacing: 20) {
                            inputGroup(title: "아이디", placeholder: "사용할 아이디를 입력하세요", text: $loginId)
                            
                            inputGroup(title: "비밀번호", placeholder: "비밀번호를 입력하세요", text: $password, isSecure: true)
                            
                            inputGroup(title: "비밀번호 확인", placeholder: "비밀번호를 다시 입력하세요", text: $passwordConfirm, isSecure: true)
                            
                            if !passwordConfirm.isEmpty && password != passwordConfirm {
                                Text("비밀번호가 일치하지 않습니다")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, -12)
                            }
                            
                            inputGroup(title: "닉네임", placeholder: "앱에서 사용할 이름을 입력하세요", text: $name)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.05))
                        )
                        
                        // 가입하기 버튼
                        Button(action: handleSignup) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.black)
                                        .padding(.trailing, 8)
                                }
                                Text("가입하기")
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
    
    private func handleSignup() {
        isLoading = true
        
        // 시뮬레이션: 회원가입 성공 처리
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            // 로그인 상태로 전환
            withAnimation(.easeInOut(duration: 0.3)) {
                appState.isLoggedIn = true
                appState.currentUser = User(
                    id: UUID(),
                    name: name,
                    profileImage: nil,
                    loginMethod: .guest // 임시로 guest 타입 사용
                )
            }
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AppState())
}
