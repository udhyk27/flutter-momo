import SwiftUI

struct SongInfoView: View {
    @Environment(\.dismiss) private var dismiss

    let songData: [String: String]
    @State private var showCloseButton = false

    var body: some View {
        ZStack {
            // 배경 이미지
            AsyncImage(url: URL(string: songData["IMAGE"] ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            } placeholder: {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
            }

            // 하단 텍스트 & 닫기버튼 오버레이
            GeometryReader { geo in
                VStack {
                    Spacer()

                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(1.5), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: geo.size.height / 2)
                    .overlay(
                        VStack(spacing: 2) {
                            Text(songData["TITLE"] ?? "")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            if showCloseButton {
                                Button(action: {
                                    dismiss()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .opacity(0.9)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(songData["ARTIST"] ?? "")
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
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
        .contentShape(Rectangle()) // 전체 탭 인식
        .onTapGesture {
            showCloseButton.toggle()
        }
    }
}
