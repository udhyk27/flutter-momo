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

struct HistoryRowView: View {
    let item: HistoryItem
    @State private var loadFailed = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if loadFailed {
                Image("no_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
            } else {
                AsyncImageView(url: URL(string: item.image)) {
                    loadFailed = true
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(12)
            }
            
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .frame(height: 120)
        .clipped()
        .cornerRadius(12)
    }
}

struct AsyncImageView: View {
    let url: URL?
    var onFail: (() -> Void)? = nil
    
    @State private var image: Image?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.3))
            } else {
                Color.gray.opacity(0.3)
                    .onAppear { loadImage() }
            }
        }
    }
    
    func loadImage() {
        guard let url = url else {
            onFail?()
            return
        }
        
        isLoading = true
        
        if let cached = ImageCache.shared.get(forKey: url.absoluteString) {
            self.image = Image(uiImage: cached)
            return
        }
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data, let uiImage = UIImage(data: data) {
                    ImageCache.shared.set(forKey: url.absoluteString, image: uiImage)
                    self.image = Image(uiImage: uiImage)
                } else {
                    onFail?()
                }
                isLoading = false
            }
        }.resume()
    }
    
    class ImageCache {
        static let shared = ImageCache()
        private init() {}

        private var cache = NSCache<NSString, UIImage>()

        func get(forKey key: String) -> UIImage? {
            return cache.object(forKey: NSString(string: key))
        }

        func set(forKey key: String, image: UIImage) {
            cache.setObject(image, forKey: NSString(string: key))
        }
    }
}

struct HistoryView: View {
    
    @StateObject var vmidc = Vmidc()
    
    @State private var historyList: [HistoryItem] = []
    @State private var displayedList: [HistoryItem] = []   // 화면에 보여줄 데이터
    
    @State private var isLoading = false
    @State private var itemsPerPage = 5
    
    @State private var isLoadingMore = false
    
    @State private var uuid: String? = nil
    
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("불러오는 중...")
                } else if displayedList.isEmpty {
                    Text("기록이 없습니다.")
                        .foregroundColor(.gray)
                } else {
                    List {


                        // 히스토리 아이템 리스트
                        ForEach(displayedList.indices, id: \.self) { index in
                            let item = displayedList[index]

                            NavigationLink(
                                destination: SongInfoView(songData: [
                                    "IMAGE": item.image,
                                    "TITLE": item.title,
                                    "ARTIST": item.artist
                                ])
                            ) {
                                HistoryRowView(item: item)
                            }
                            .onAppear {
                                if index == displayedList.count - 1 {
                                    loadMore()
                                }
                            }
                        }
                        
                        // 삭제 버튼을 맨 위 셀로
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            HStack {
                                Spacer()
                                Text("기록 전체 삭제")
                                    .foregroundColor(.red)
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .frame(height: 36) // 버튼 높이 설정
                        .listRowInsets(EdgeInsets()) // 인셋 제거 (선택)
                        .padding(.vertical, 8)
                    }
                    .listStyle(.plain)
                }
            }
            .onAppear {
                if uuid == nil {
                    uuid = vmidc.getDeviceUUID()
                }
                fetchHistory()
            }
            .alert(isPresented: $showDeleteAlert) {
                          Alert(
                              title: Text("정말 삭제하시겠습니까?"),
                              message: Text("모든 히스토리가 삭제됩니다."),
                              primaryButton: .destructive(Text("삭제")) {
                                  delHistory()
                              },
                              secondaryButton: .cancel(Text("취소"))
                          )
                      }
        }
        
    }
    
    

        
    
    


    func fetchHistory() {
        guard let uid = uuid,
              let url = URL(string: "https://www.mo-mo.co.kr/api/get_song_history/json?uid=\(uid)") else { return }

        DispatchQueue.main.async {
            isLoading = true
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
                    DispatchQueue.main.async {
                        self.historyList = decoded
                        self.displayedList = Array(decoded.prefix(itemsPerPage))
                        self.isLoading = false
                    }
                } else {
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
    
    func loadMore() {
        guard !isLoadingMore else { return }
        let currentCount = displayedList.count
        let totalCount = historyList.count
        
        guard currentCount < totalCount else { return }
        
        isLoadingMore = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let nextCount = min(currentCount + itemsPerPage, totalCount)
            displayedList.append(contentsOf: historyList[currentCount..<nextCount])
            isLoadingMore = false
        }
    }
    
    func delHistory() {
        guard let uid = uuid,
              let url = URL(string: "https://www.mo-mo.co.kr/api/get_song_history/json?uid=\(uid)&proc=del") else { return }

        isLoading = true

        URLSession.shared.dataTask(with: url) { _, _, error in
            defer {
                DispatchQueue.main.async {
                    isLoading = false
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
