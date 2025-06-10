import SwiftUI

struct HistoryItem: Decodable, Identifiable {
    let id = UUID() // 고유 ID 부여
    let image: String
    let title: String
    let artist: String

    enum CodingKeys: String, CodingKey {
        case image = "IMAGE"
        case title = "TITLE"
        case artist = "ARTIST"
    }
}
struct HistoryView: View {
    
    @StateObject var vmidc = Vmidc()
    
    @State private var historyList: [HistoryItem] = []
    @State private var isLoading = false
    
    @State private var uuid: String? = nil

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("불러오는 중...")
                } else if historyList.isEmpty {
                    Text("기록이 없습니다.")
                        .foregroundColor(.gray)
                } else {
                    List(historyList, id: \.title) { item in
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(url: URL(string: item.image)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(12)

                            // 텍스트 오버레이
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(item.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.4)) // 반투명 배경
                        }
                        .listRowInsets(EdgeInsets()) // 이미지가 리스트 끝까지 차게
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
//            .navigationTitle("히스토리")
            .onAppear {
                if uuid == nil {
                    uuid = vmidc.getDeviceUUID()  // 한 번만 가져오기
                }
                fetchHistory()
            }
        }
    }

    func fetchHistory() {
        guard let uid = uuid,
                      let url = URL(string: "https://www.mo-mo.co.kr/api/get_song_history/json?uid=\(uid)") else { return }

        DispatchQueue.main.async {
            isLoading = true
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
                    DispatchQueue.main.async {
                        self.historyList = decoded
                        self.isLoading = false
                    }
                } else {
                    print("받은 JSON:\n" + (String(data: data, encoding: .utf8) ?? "디코딩 불가"))
                    print("디코딩 실패")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            } else {
                print("네트워크 에러: \(error?.localizedDescription ?? "알 수 없음")")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }

    
    func delHistory() {
        let uid = vmidc.getDeviceUUID()
        guard let url = URL(string: "https://www.mo-mo.co.kr/api/get_song_history/json?uid=\(uid)&proc=del") else { return }

        isLoading = true

        URLSession.shared.dataTask(with: url) { data, response, error in
            defer {
                DispatchQueue.main.async {
                    isLoading = false
                    // 삭제 후 다시 히스토리 갱신
                    fetchHistory()
                }
            }

            if let error = error {
                print("삭제 요청 실패: \(error.localizedDescription)")
                return
            }

            print("히스토리 삭제 완료")
        }.resume()
    }
}
