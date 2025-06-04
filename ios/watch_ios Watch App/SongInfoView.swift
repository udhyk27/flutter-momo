//
//  SongInfoView.swift
//  Runner
//
//  Created by 방경식 on 5/29/25.
//
import SwiftUI

struct SongInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 전체 화면 배경 이미지
            AsyncImage(url: URL(string: "https://adm.airmonitor.co.kr/resource_music/2019/064/KA0094064/KA0094064.jpg")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } placeholder: {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
            }

            // 텍스트와 버튼
            VStack(spacing: 10) {
                Spacer()

                VStack(spacing: 6) {
                    Text("Home Sweet Home")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("카더가든")
                        .foregroundColor(.white)

                    Text("APARTMENT")
                        .foregroundColor(.white)

                    Text("2017.12.02")
                        .foregroundColor(.white)
                }
                .multilineTextAlignment(.center)

                Button("닫기") {
                    dismiss()
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.top, 20)

                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}
