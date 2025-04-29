import SwiftUI

// 기본 화면
struct ContentView: View {
    @StateObject private var audioManager = WatchAudioManager()

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                if audioManager.isRecognizing {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)

                        Text("음원 인식 중입니다...")
                            .font(.headline)
                            .padding(.top, 10)
                    }
                } else {
                    Button(action: audioManager.startRecording) {
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
            .navigationDestination(isPresented: $audioManager.navigateToSongInfo) {
                SongInfoView()
            }
        }
    }
}


// 음악인식 결과
struct SongInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.3)) // 빈 배경색
                        ProgressView()
                    }
                    .frame(width: 150, height: 150)
                }
                
                // 곡 정보
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

                Button("닫기") {
                    dismiss()
                }
                .padding()
                .padding(.top, 20)
                .padding(.bottom, 30)
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
