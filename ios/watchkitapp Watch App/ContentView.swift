import SwiftUI

// 기본 화면
struct ContentView: View {
    @StateObject private var audioManager = WatchAudioManager()
    @State private var isRecognizing = false // 녹음 중 표시
    @State private var songFound = false // 곡 인식 성공여부
    @State private var navigateToSongInfo = false // 네비게이션 상태

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                if isRecognizing {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)

                        Text("음원 인식 중입니다...")
                            .font(.headline)
                            .padding(.top, 10)
                    }
                } else {
                    Button(action: startRec) {
                        Image("momo_btn")
                            .resizable()
                            .frame(width: 120.0, height: 120.0)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .navigationBarBackButtonHidden(true) // 뒤로가기 버튼 숨기기
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor(red: 255/255, green: 195/255, blue: 200/255, alpha: 1.0)))
            .navigationDestination(isPresented: $navigateToSongInfo) {
                SongInfoView()
            }
        }
    }
    
    private func startRec() {
        
        // iOS 데이터 전송
        audioManager.wakeUpiPhone()
        audioManager.startRecording()
        
        isRecognizing = true // 녹음 중
        songFound = true // 노래 찾았다고 가정

        // 3초 인디케이터
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRecognizing = false
            
            if songFound {
                navigateToSongInfo = true
            }
            
            
        }
        
        
    }
}

struct SongInfoView: View {
    var body: some View {
        ScrollView {
            VStack {
                
                Spacer()
                
                AsyncImage(url: URL(string: "https://adm.airmonitor.co.kr/resource_music/2019/064/KA0094064/KA0094064.jpg")) { image in
                    image
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                
                VStack(alignment: .leading) {
                    Text("Home Sweet Home") // 곡 제목
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("카더가든") // 가수명
                        .foregroundColor(.black)
                    
                    Text("APARTMENT") // 앨범명
                        .foregroundColor(.black)
                    
                    Text("2017.12.02") // 발매일자
                        .foregroundColor(.black)
                }

                
                
                NavigationLink("닫기", destination: ContentView())
                    .padding()
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .navigationBarBackButtonHidden(true) // 뒤로가기 버튼 숨기기
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
