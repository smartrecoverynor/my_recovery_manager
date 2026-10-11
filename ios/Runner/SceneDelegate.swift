import Flutter
import UIKit
import UserNotifications

class SceneDelegate: FlutterSceneDelegate {

  private let pendingRegionKey =
    "mrm.pendingRiskyPlaceRegion"

  private let notificationTappedKey =
    "mrm.riskyPlaceNotificationTapped"

  private var launchNotificationResponse:
    UNNotificationResponse?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(
      scene,
      willConnectTo: session,
      options: connectionOptions
    )

    if let response =
      connectionOptions.notificationResponse {

      launchNotificationResponse = response

      storeNotificationResponse(response)
    }
  }

  override func sceneDidBecomeActive(
    _ scene: UIScene
  ) {
    super.sceneDidBecomeActive(scene)

    if let response = launchNotificationResponse {
      storeNotificationResponse(response)
      launchNotificationResponse = nil
    }
  }

  private func storeNotificationResponse(
    _ response: UNNotificationResponse
  ) {
    let userInfo =
      response.notification.request.content.userInfo

    guard let identifier =
      userInfo["riskyPlaceId"] as? String else {
      return
    }

    UserDefaults.standard.set(
      identifier,
      forKey: pendingRegionKey
    )

    UserDefaults.standard.set(
      true,
      forKey: notificationTappedKey
    )

    UNUserNotificationCenter.current()
      .removeDeliveredNotifications(
        withIdentifiers: [
          response.notification.request.identifier
        ]
      )
  }
}