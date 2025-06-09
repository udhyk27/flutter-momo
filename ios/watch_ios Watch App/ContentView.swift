import SwiftUI

struct ContentView: View {
    @StateObject var vmidc = Vmidc()
    @State private var navigateToSongInfo = false
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
                        if appState.isRecording {
                            vmidc.stop()
                        } else {
                            vmidc.checkPermission()
                        }
                    }) {
                        if appState.isRecording {
                            Text("음악 인식 중...")
                                .foregroundColor(.white)
                                .font(.title3)
                                .bold()
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
                }
            }
        }
    }
}
