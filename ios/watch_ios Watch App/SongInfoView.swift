import SwiftUI

struct SongInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    let songData: [String: String]
    
    var body: some View {
        ZStack {
            // 배경 이미지
            AsyncImage(url: URL(string: songData["IMAGE"] ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped() // 이미지 영역 밖 잘린 부분 숨김
                    .ignoresSafeArea()
            } placeholder: {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
            }
            
            // 닫기 버튼 - 상단 우측
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .opacity(0.8)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            
            // 텍스트와 그라데이션 배경 - 하단에 딱 붙임
            GeometryReader { geo in
                VStack {
                    Spacer() // 위 공간은 비우고
                    
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(1.5), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: geo.size.height / 2)  // 화면 높이 절반만큼
                    .overlay(
                        VStack(spacing: 2) {
                            Text(songData["TITLE"] ?? "")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text(songData["ARTIST"] ?? "")
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.bottom, 20)
                        .padding(.horizontal, 20),
                        alignment: .bottom
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
