import SwiftUI

struct ContentView: View {
    @StateObject var vmidc = Vmidc()
    @State private var navigateToSongInfo = false
    @StateObject private var appState = AppState.shared
    
    @State private var showHistory = false  // 추가
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 62/255, green: 195/255, blue: 255/255),   // 하늘색
                        Color(red: 194/255, green: 40/255, blue: 222/255)   // 보라색
//                        Color(red: 0/255, green: 0/255, blue: 0/255),
//                        Color(red: 158/255, green: 158/255, blue: 158/255)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    if !appState.isRecording {
                        Text("모모를 눌러주세요")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.bottom, 8)  // 버튼과의 간격
                    }
                    
                    
                    Button(action: {
                        if appState.isRecording {
                            vmidc.stop()
                        } else {
                            vmidc.checkPermission()
                        }
                    }) {
                        if appState.isRecording {
                            VStack(spacing: 2) { // 텍스트와 로딩바 사이 약간의 간격
                                Text(vmidc.statusText)
                                    .foregroundColor(.white)
                                    .font(.title3)
                                    .bold()
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        } else {
                            Image("blue_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                
                VStack {
                    
                    if !appState.isRecording {
                        HStack {
                            Spacer()
                            Button(action: {
                                showHistory = true
                            }) {
                                Image(systemName: "chevron.forward")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    
                    Spacer()
                }
            
                .navigationDestination(isPresented: $showHistory) {
                    HistoryView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    vmidc.openSession()
                }
                .onDisappear {
                    vmidc.closeSession()
                }
            }
            .navigationBarBackButtonHidden(true)
            .onChange(of: vmidc.foundSongData) { newValue in
                if newValue != nil {
                    navigateToSongInfo = true
                }
            }
            .navigationDestination(isPresented: $navigateToSongInfo) {
                if let songData = vmidc.foundSongData {
                    SongInfoView(songData: songData)
                        .onDisappear{
                            vmidc.foundSongData = nil
                            navigateToSongInfo = false
                        }
                }
            }
        }
    }
}
