import SwiftUI

// 기본 화면
struct ContentView: View {
    @State private var showSongInfo = false

    var body: some View {
        NavigationStack {
            VStack {
                Button("Test") {
                }

                Spacer()
            }
            .navigationBarBackButtonHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor(red: 255/255, green: 195/255, blue: 200/255, alpha: 1.0)))
            .navigationDestination(isPresented: $showSongInfo) {
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
                            .fill(Color.gray.opacity(0.3))
                        ProgressView()
                    }
                    .frame(width: 150, height: 150)
                }

                VStack(alignment: .leading) {
                    Text("Home Sweet Home")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Text("카더가든")
                        .foregroundColor(.black)

                    Text("APARTMENT")
                        .foregroundColor(.black)

                    Text("2017.12.02")
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
            .navigationBarBackButtonHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
