import Flutter
import UIKit
import Firebase
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
    
    private var eventSink: FlutterEventSink?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
      
        // Firebase 초기화
        FirebaseApp.configure()
    
        // Watch 연결
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }

        let controller = window?.rootViewController as! FlutterViewController
        let eventChannel = FlutterEventChannel(name: "watch_channel", binaryMessenger: controller.binaryMessenger)
        eventChannel.setStreamHandler(self)

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // 워치에서 메시지 수신 (오디오 데이터 포함)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                switch action {
                case "wakeUp":
                    print("iPhone 앱 자동 실행 요청 받음!")
                    self.openAppFromWatch()

                case "watchRec":
                    print("워치에서 'watchRec' 신호 받음")
                    self.eventSink?("watchRec")

                default:
                    print("알 수 없는 액션: \(action)")
                }
            } else if let base64String = message["audioData"] as? String {
                print("워치에서 오디오 데이터 받음")
                self.eventSink?(base64String)
            }
        }
    }

    // 필수 메서드 (WCSession 활성화)
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        print("iOS 세션 활성화 완료: \(state.rawValue)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}

// Flutter와 EventChannel 연결
extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
