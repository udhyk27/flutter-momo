import UIKit
import Flutter
import Firebase
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // 1. Firebase 초기화
        FirebaseApp.configure()

        // 2. FlutterViewController 생성 및 window 설정
        let flutterViewController = FlutterViewController()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = flutterViewController
        self.window?.makeKeyAndVisible()

        // 3. 플러그인 등록
        GeneratedPluginRegistrant.register(with: flutterViewController)

        // 4. 오디오 세션 설정
        configureAudioSession()
        observeRouteChanges()

        // 5. MethodChannel 등록 - 오디오 세션 설정 Flutter로 전달
        let channel = FlutterMethodChannel(
            name: "com.aiid.momo/audio_session",
            binaryMessenger: flutterViewController.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
            if call.method == "reconfigureSession" {
                self.configureAudioSession()
                result(true)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // 오디오 세션 설정 함수
    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance() // 싱글톤 오디오 세션

            try session.setCategory(
                .playAndRecord, // 재생 & 녹음 모드 설정
                mode: .measurement, // 노이즈 제거 최소화 (원본 음질 보존)
                options: [
                    .mixWithOthers, // 다른 앱 동시 재생
                    .defaultToSpeaker, // 기본 외부 스피커
                    .allowBluetoothA2DP // A2DP만 허용 (HFP 전화용 블루투스 차단)
                ]
            )

            // 내장 마이크 고정 (블루투스/차량 연결돼도 내장 마이크 유지)
            if let builtInMic = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
                try session.setPreferredInput(builtInMic)
            }

        } catch {
            print("Audio session error: \(error)")
        }
    }

    // 블루투스/차량 연결 등 라우팅 변경 감지 → 세션 재설정
    private func observeRouteChanges() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] notification in
            guard let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

            switch reason {
            case .newDeviceAvailable,    // 블루투스/이어폰 연결됨
                 .oldDeviceUnavailable:  // 블루투스/이어폰 해제됨
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.configureAudioSession()
                }
            default:
                break // 녹음 시작/종료 등 나머지는 무시
            }
        }
    }
}
