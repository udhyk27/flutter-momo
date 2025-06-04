import SwiftUI

// 기본 화면
struct ContentView: View {
//    @State private var showSongInfo = false
    
    let vmidc = Vmidc()
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 62/255, green: 195/255, blue: 255/255),   // 하늘색
                        Color(red: 194/255, green: 40/255, blue: 222/255)   // 보라색
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    Button(action: {
                        // 버튼 클릭 액션
                        vmidc.checkPermission() // 마이크 권한 확인하고 허용이면 start
                    }) {
                        if (appState.isRecording) {
                            Text("음악 인식 중...")
                                .foregroundColor(.white)
                                .font(.title3)
                                .bold()
                        } else {
                            Image("blue_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100) // 원하는 크기로 조절
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    vmidc.openSession() // 오디오 세션 오픈
                }
                .onDisappear {
                    vmidc.closeSession() // 오디오 세션 닫기
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}



#Preview {
    ContentView()
}
