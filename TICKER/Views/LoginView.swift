import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경 그라데이션
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.08, green: 0.08, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 배경 장식 원들
            GeometryReader { geo in
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -50)
                
                Circle()
                    .fill(Color.yellow.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geo.size.width - 150, y: geo.size.height - 200)
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // 로고 및 타이틀
                VStack(spacing: 16) {
                    // 앱 아이콘
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.8), Color.green],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: .green.opacity(0.4), radius: 20, y: 10)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("TICKER")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("친구에게 투자하고, 할 일로 주가를 올려라")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 60)
                
                // 로그인 카드
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("시작하기")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text("카카오 계정으로 간편하게 로그인하세요")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    
                    // 카카오 로그인 버튼
                    Button(action: handleKakaoLogin) {
                        HStack(spacing: 12) {
                            // 카카오 아이콘
                            Image(systemName: "message.fill")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("카카오 로그인")
                                .font(.system(size: 16, weight: .semibold))
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.2, green: 0.14, blue: 0.07)))
                                    .scaleEffect(0.8)
                            }
                        }
                        .foregroundStyle(Color(red: 0.2, green: 0.14, blue: 0.07))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(red: 0.996, green: 0.898, blue: 0.0)) // 카카오 노란색
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                    .shadow(color: Color(red: 0.996, green: 0.898, blue: 0.0).opacity(0.3), radius: 15, y: 5)
                    
                    // 구분선
                    HStack {
                        Rectangle()
                            .fill(.white.opacity(0.1))
                            .frame(height: 1)
                        
                        Text("또는")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(.white.opacity(0.1))
                            .frame(height: 1)
                    }
                    
                    // 회원가입 버튼 (Apple 로그인 대체)
                    NavigationLink(destination: SignupView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("이메일로 회원가입")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                    
                    // 게스트 로그인
                    Button(action: handleGuestLogin) {
                        Text("게스트로 둘러보기")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial.opacity(0.3))
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.white.opacity(0.05))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
                .frame(maxWidth: 380)
                
                Spacer()
                
                // 하단 문구
                VStack(spacing: 8) {
                    Text("로그인 시 이용약관 및 개인정보 처리방침에 동의합니다")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                    
                    HStack(spacing: 4) {
                        Text("이용약관")
                        Text("·")
                        Text("개인정보 처리방침")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.bottom, 32)
            .padding(.horizontal, 40)
        }
        }
    } // End of NavigationStack
        .alert("로그인 오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Login Handlers
    
    private func handleKakaoLogin() {
        isLoading = true
        
        // 실제 앱에서는 KakaoSDK를 사용하여 로그인 처리
        // KakaoSDKUser.UserApi.shared.loginWithKakaoTalk { ... }
        
        // 시뮬레이션: 1.5초 후 로그인 완료
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                appState.isLoggedIn = true
                appState.currentUser = User(
                    id: UUID(),
                    name: "김주식",
                    profileImage: nil,
                    loginMethod: .kakao
                )
            }
            isLoading = false
        }
    }
    
    private func handleAppleLogin() {
        isLoading = true
        
        // 실제 앱에서는 AuthenticationServices를 사용하여 로그인 처리
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                appState.isLoggedIn = true
                appState.currentUser = User(
                    id: UUID(),
                    name: "Apple 사용자",
                    profileImage: nil,
                    loginMethod: .apple
                )
            }
            isLoading = false
        }
    }
    
    private func handleGuestLogin() {
        withAnimation(.easeInOut(duration: 0.3)) {
            appState.isLoggedIn = true
            appState.currentUser = User(
                id: UUID(),
                name: "게스트",
                profileImage: nil,
                loginMethod: .guest
            )
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
