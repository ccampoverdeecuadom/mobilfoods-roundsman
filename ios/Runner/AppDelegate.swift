import UIKit
import Flutter
import Firebase
import GoogleMaps

func registerPlugins(registry: FlutterPluginRegistry) -> () {
    if (!registry.hasPlugin("BackgroundLocatorPlugin")) {
        GeneratedPluginRegistrant.register(with: registry)
    }
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
      //    INIT FIREBASE
          FirebaseApp.configure()
          

          
      //    CONFIG FOR REMOTE NOTIFICATIONS
          if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
              options: authOptions,
              completionHandler: {_, _ in })
          } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
          }

          application.registerForRemoteNotifications()
      GeneratedPluginRegistrant.register(with: self)
      
      //    CONFIG API KEY FOR GOOGLE MAPS
          GMSServices.provideAPIKey("AIzaSyDpePpWyxe6PbSvyBVwmHl1LDvKvkoLJ8Y")
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
  }

