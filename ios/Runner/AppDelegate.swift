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

        // 4. 오디오 세션 설정 (딜레이 후 실행)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.configureAudioSession()
            self.observeRouteChanges()
        }

        // 5. MethodChannel 등록
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

    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [
                    .mixWithOthers,
                    .defaultToSpeaker,
                    .allowBluetoothA2DP
                ]
            )
            
            if let builtInMic = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
                try session.setPreferredInput(builtInMic)
            }
            
            try session.setActive(true)
            
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func observeRouteChanges() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.configureAudioSession()
            }
        }
    }
}
