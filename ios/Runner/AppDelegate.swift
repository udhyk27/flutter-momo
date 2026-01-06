import UIKit
import Flutter
import Firebase

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
        self.window = UIWindow(frame: UIScreen.main.bounds) // 이미 존재하는 window 사용
        self.window?.rootViewController = flutterViewController
        self.window?.makeKeyAndVisible()

        // 3. 플러그인 등록
        GeneratedPluginRegistrant.register(with: flutterViewController)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
