import Flutter
import UIKit
import UserNotifications
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate,
    FlutterImplicitEngineDelegate,
    CLLocationManagerDelegate {

  private let locationManager = CLLocationManager()

  private let pendingRegionKey =
    "mrm.pendingRiskyPlaceRegion"

  private let notificationTappedKey =
    "mrm.riskyPlaceNotificationTapped"

  private let alertConfigPrefix =
    "mrm.riskyPlaceAlertConfig."

  private let cooldownPrefix =
    "mrm.riskyPlaceLastNotified."

  private let notificationCooldown:
    TimeInterval = 2 * 60 * 60

  // MARK: - Pending location request

  private var pendingMonitoringArguments:
    [String: Any]?

  private var pendingMonitoringResult:
    FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions:
      [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    locationManager.delegate = self

    UNUserNotificationCenter.current().delegate = self

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  // MARK: - Flutter engine

  func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    GeneratedPluginRegistrant.register(
      with: engineBridge.pluginRegistry
    )

    let channel = FlutterMethodChannel(
      name: "mrm/risky_places",
      binaryMessenger:
        engineBridge.applicationRegistrar.messenger()
    )

    channel.setMethodCallHandler {
      [weak self] call, result in

      guard let self = self else {
        result(
          FlutterError(
            code: "APP_DELEGATE_UNAVAILABLE",
            message: "AppDelegate er ikke tilgjengelig.",
            details: nil
          )
        )
        return
      }

      switch call.method {

      case "startMonitoring":
        self.startMonitoring(
          call: call,
          result: result
        )

      case "stopMonitoring":
        self.stopMonitoring(
          call: call,
          result: result
        )

      case "stopAllMonitoring":
        stopAllMonitoring(result: result)

      case "syncMonitoring":
        self.syncMonitoring(
          call: call,
          result: result
        )

      case "consumeTappedRiskyPlace":
        self.consumeTappedRiskyPlace(
          result: result
        )

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Start monitoring

  private func startMonitoring(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let args = call.arguments as? [String: Any],
      let _ = args["id"] as? String,
      let _ = args["latitude"] as? Double,
      let _ = args["longitude"] as? Double,
      let _ = args["radiusMeters"] as? Double
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Ugyldige argumenter for region.",
          details: nil
        )
      )
      return
    }

    let status = locationManager.authorizationStatus

    switch status {

    case .notDetermined:

      pendingMonitoringArguments = args
      pendingMonitoringResult = result

      locationManager.requestWhenInUseAuthorization()

    case .authorizedWhenInUse:

      pendingMonitoringArguments = args
      pendingMonitoringResult = result

      if #available(iOS 13.4, *) {
        locationManager.requestAlwaysAuthorization()
      } else {
        completePendingMonitoring()
      }

    case .authorizedAlways:

      startMonitoringWithArguments(
        args,
        result: result
      )

    case .denied, .restricted:

      result(
        FlutterError(
          code: "LOCATION_PERMISSION_DENIED",
          message:
            "Posisjonstillatelse er ikke tilgjengelig. "
            + "Du kan endre dette i Innstillinger.",
          details: nil
        )
      )

    @unknown default:

      result(
        FlutterError(
          code: "LOCATION_PERMISSION_UNKNOWN",
          message:
            "Kunne ikke fastslå status for posisjonstillatelsen.",
          details: nil
        )
      )
    }
  }

  // MARK: - Complete pending monitoring

  private func completePendingMonitoring() {

    guard
      let args = pendingMonitoringArguments,
      let result = pendingMonitoringResult
    else {
      return
    }

    pendingMonitoringArguments = nil
    pendingMonitoringResult = nil

    let status = locationManager.authorizationStatus

    switch status {

    case .authorizedAlways:

      startMonitoringWithArguments(
        args,
        result: result
      )

    case .authorizedWhenInUse:

      if #available(iOS 13.4, *) {

        pendingMonitoringArguments = args
        pendingMonitoringResult = result

        locationManager.requestAlwaysAuthorization()

      } else {

        result(
          FlutterError(
            code: "LOCATION_PERMISSION_INSUFFICIENT",
            message:
              "Appen trenger tilgang til posisjon også "
              + "når den ikke er i bruk.",
            details: nil
          )
        )
      }

    case .denied, .restricted:

      result(
        FlutterError(
          code: "LOCATION_PERMISSION_DENIED",
          message:
            "Posisjonstillatelse er ikke tilgjengelig. "
            + "Du kan endre dette i Innstillinger.",
          details: nil
        )
      )

    default:

      result(
        FlutterError(
          code: "LOCATION_PERMISSION_INSUFFICIENT",
          message:
            "Appen fikk ikke nødvendig posisjonstillatelse.",
          details: nil
        )
      )
    }
  }

  // MARK: - Start authorized monitoring

  private func startMonitoringWithArguments(
    _ args: [String: Any],
    result: FlutterResult
  ) {
    guard
      let id = args["id"] as? String,
      let latitude = args["latitude"] as? Double,
      let longitude = args["longitude"] as? Double,
      let radius = args["radiusMeters"] as? Double
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Ugyldige argumenter for region.",
          details: nil
        )
      )
      return
    }

    if let alerts =
      args["alerts"] as? [[String: Any]] {

      UserDefaults.standard.set(
        alerts,
        forKey: alertConfigPrefix + id
      )
    }

    let center = CLLocationCoordinate2D(
      latitude: latitude,
      longitude: longitude
    )

    for existingRegion in locationManager.monitoredRegions {

      if existingRegion.identifier == id {

        if let existingCircular =
          existingRegion as? CLCircularRegion {

          let sameCenter =
            abs(
              existingCircular.center.latitude -
              latitude
            ) < 0.000001 &&
            abs(
              existingCircular.center.longitude -
              longitude
            ) < 0.000001

          let sameRadius =
            abs(
              existingCircular.radius -
              radius
            ) < 0.5

          if sameCenter && sameRadius {
            result(nil)
            return
          }
        }

        locationManager.stopMonitoring(
          for: existingRegion
        )
      }
    }

    let region = CLCircularRegion(
      center: center,
      radius: radius,
      identifier: id
    )

    region.notifyOnEntry = true
    region.notifyOnExit = false

    locationManager.startMonitoring(
      for: region
    )

    result(nil)
  }

  // MARK: - Location authorization changes

  func locationManagerDidChangeAuthorization(
    _ manager: CLLocationManager
  ) {
    guard pendingMonitoringArguments != nil else {
      return
    }

    let status = manager.authorizationStatus

    switch status {

    case .authorizedWhenInUse:

      if #available(iOS 13.4, *) {
        manager.requestAlwaysAuthorization()
      }

    case .authorizedAlways:

      completePendingMonitoring()

    case .denied, .restricted:

      completePendingMonitoring()

    default:
      break
    }
  }

  // MARK: - Stop monitoring

  private func stopMonitoring(
    call: FlutterMethodCall,
    result: FlutterResult
  ) {
    guard
      let args = call.arguments as? [String: Any],
      let id = args["id"] as? String
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Manglende region-ID.",
          details: nil
        )
      )
      return
    }

    for region in locationManager.monitoredRegions {
      if region.identifier == id {
        locationManager.stopMonitoring(
          for: region
        )
      }
    }

    UserDefaults.standard.removeObject(
      forKey: alertConfigPrefix + id
    )

    result(nil)
  }

  private func stopAllMonitoring(
    result: @escaping FlutterResult
  ) {
    for region in locationManager.monitoredRegions {
      locationManager.stopMonitoring(for: region)
    }

    let defaults = UserDefaults.standard

    let keys = defaults.dictionaryRepresentation().keys

    for key in keys {
      if key.hasPrefix(alertConfigPrefix) ||
         key.hasPrefix(cooldownPrefix) {
        defaults.removeObject(forKey: key)
      }
    }

    defaults.removeObject(forKey: pendingRegionKey)
    defaults.removeObject(forKey: notificationTappedKey)

    result(nil)
  }
  // MARK: - Synchronize regions

  private func syncMonitoring(
    call: FlutterMethodCall,
    result: FlutterResult
  ) {
    guard
      let args = call.arguments as? [String: Any],
      let places = args["places"] as? [[String: Any]]
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Ugyldig liste over risikosteder.",
          details: nil
        )
      )
      return
    }

    let desiredIDs = Set(
      places.compactMap {
        $0["id"] as? String
      }
    )

    // Fjern gamle regioner.
    for region in locationManager.monitoredRegions {

      if !desiredIDs.contains(region.identifier) {

        locationManager.stopMonitoring(
          for: region
        )

        UserDefaults.standard.removeObject(
          forKey:
            alertConfigPrefix + region.identifier
        )
      }
    }

    for place in places {

      guard
        let id = place["id"] as? String,
        let latitude = place["latitude"] as? Double,
        let longitude = place["longitude"] as? Double,
        let radius = place["radiusMeters"] as? Double
      else {
        continue
      }

      let alerts =
        place["alerts"] as? [[String: Any]] ?? []

      UserDefaults.standard.set(
        alerts,
        forKey: alertConfigPrefix + id
      )

      var existing:
        CLCircularRegion?

      for region in locationManager.monitoredRegions {
        if region.identifier == id {
          existing = region as? CLCircularRegion
          break
        }
      }

      if let existing = existing {

        let sameCenter =
          abs(
            existing.center.latitude -
            latitude
          ) < 0.000001 &&
          abs(
            existing.center.longitude -
            longitude
          ) < 0.000001

        let sameRadius =
          abs(
            existing.radius -
            radius
          ) < 0.5

        if sameCenter && sameRadius {
          continue
        }

        locationManager.stopMonitoring(
          for: existing
        )
      }

      let region = CLCircularRegion(
        center: CLLocationCoordinate2D(
          latitude: latitude,
          longitude: longitude
        ),
        radius: radius,
        identifier: id
      )

      region.notifyOnEntry = true
      region.notifyOnExit = false

      locationManager.startMonitoring(
        for: region
      )
    }

    result(nil)
  }

  // MARK: - Notification state

  private func consumeTappedRiskyPlace(
    result: FlutterResult
  ) {
    let tapped =
      UserDefaults.standard.bool(
        forKey: notificationTappedKey
      )

    guard tapped else {
      result(nil)
      return
    }

    let identifier =
      UserDefaults.standard.string(
        forKey: pendingRegionKey
      )

    UserDefaults.standard.removeObject(
      forKey: notificationTappedKey
    )

    UserDefaults.standard.removeObject(
      forKey: pendingRegionKey
    )

    result(identifier)
  }

  // MARK: - Region entry

  func locationManager(
    _ manager: CLLocationManager,
    didEnterRegion region: CLRegion
  ) {
    let identifier = region.identifier

    guard shouldNotify(for: identifier) else {
      return
    }

    UserDefaults.standard.set(
      identifier,
      forKey: pendingRegionKey
    )

    UserDefaults.standard.set(
      false,
      forKey: notificationTappedKey
    )

    let content =
      UNMutableNotificationContent()

    content.title =
      "Risikofylt sted"

    content.body =
      "Du befinner deg ved et registrert risikosted."

    content.sound = .default

    content.userInfo = [
      "riskyPlaceId": identifier
    ]

    let notificationIdentifier =
      "risky-place-\(identifier)"

    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(
        withIdentifiers: [
          notificationIdentifier
        ]
      )

    UNUserNotificationCenter.current()
      .removeDeliveredNotifications(
        withIdentifiers: [
          notificationIdentifier
        ]
      )

    let request =
      UNNotificationRequest(
        identifier: notificationIdentifier,
        content: content,
        trigger: nil
      )

    UNUserNotificationCenter.current().add(
      request
    ) { [weak self] error in

      if let _ = error {
        return
      }

      UserDefaults.standard.set(
        Date(),
        forKey:
          self?.cooldownKey(for: identifier) ?? ""
      )
    }
  }

  // MARK: - Notification decision

  private func shouldNotify(
    for identifier: String
  ) -> Bool {

    guard let alerts =
      UserDefaults.standard.array(
        forKey:
          alertConfigPrefix + identifier
      ) as? [[String: Any]] else {

      // Ingen konfigurerte perioder =
      // ikke send notification.
      return false
    }

    guard !alerts.isEmpty else {
      return false
    }

    let now = Date()

    let active =
      alerts.contains {
        isAlertActive(
          $0,
          at: now
        )
      }

    guard active else {
      return false
    }

    if let last =
      UserDefaults.standard.object(
        forKey:
          cooldownKey(for: identifier)
      ) as? Date {

      let elapsed =
        now.timeIntervalSince(last)

      if elapsed < notificationCooldown {
        return false
      }
    }

    return true
  }

  private func isAlertActive(
    _ alert: [String: Any],
    at date: Date
  ) -> Bool {

    guard
      let daysString =
        alert["daysOfWeek"] as? String,
      let fromTime =
        alert["fromTime"] as? String,
      let toTime =
        alert["toTime"] as? String
    else {
      return false
    }

    guard
      let fromMinutes =
        timeToMinutes(fromTime),
      let toMinutes =
        timeToMinutes(toTime)
    else {
      return false
    }

    let activeDays =
      Set(
        daysString
          .split(separator: ",")
          .compactMap {
            Int($0)
          }
      )

    let calendar =
      Calendar.current

    let weekday =
      calendar.component(
        .weekday,
        from: date
      )

    // iOS:
    // Sunday = 1
    // Monday = 2
    // ...
    // Saturday = 7

    // Appen bruker:
    // Monday = 1
    // ...
    // Sunday = 7
    let appWeekday: Int

    if weekday == 1 {
      appWeekday = 7
    } else {
      appWeekday = weekday - 1
    }

    let hour =
      calendar.component(
        .hour,
        from: date
      )

    let minute =
      calendar.component(
        .minute,
        from: date
      )

    let currentMinutes =
      hour * 60 + minute

    // Vanlig periode.
    if fromMinutes <= toMinutes {

      return activeDays.contains(
        appWeekday
      ) &&
      currentMinutes >= fromMinutes &&
      currentMinutes <= toMinutes
    }

    // Periode over midnatt.
    //
    // Eksempel:
    // mandag 22:00–02:00
    //
    // 23:00 mandag:
    // aktiv fordi mandag er valgt.
    //
    // 01:00 tirsdag:
    // aktiv fordi mandagens periode fortsatt pågår.

    if currentMinutes >= fromMinutes {
      return activeDays.contains(
        appWeekday
      )
    }

    if currentMinutes <= toMinutes {

      let previousWeekday =
        appWeekday == 1
          ? 7
          : appWeekday - 1

      return activeDays.contains(
        previousWeekday
      )
    }

    return false
  }

  private func timeToMinutes(
    _ value: String
  ) -> Int? {

    let parts =
      value.split(
        separator: ":"
      )

    guard parts.count == 2 else {
      return nil
    }

    guard
      let hour = Int(parts[0]),
      let minute = Int(parts[1]),
      hour >= 0,
      hour <= 23,
      minute >= 0,
      minute <= 59
    else {
      return nil
    }

    return hour * 60 + minute
  }

  private func cooldownKey(
    for identifier: String
  ) -> String {
    return cooldownPrefix + identifier
  }

  // MARK: - Notification tap

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler:
      @escaping () -> Void
  ) {
    let userInfo =
      response.notification.request.content.userInfo

    let identifier =
      userInfo["riskyPlaceId"] as? String

    if let identifier = identifier {
      UserDefaults.standard.set(
        identifier,
        forKey: pendingRegionKey
      )
    }

    UserDefaults.standard.set(
      true,
      forKey: notificationTappedKey
    )

    center.removeDeliveredNotifications(
      withIdentifiers: [
        response.notification.request.identifier
      ]
    )

    completionHandler()
  }

  // MARK: - Region exit

  func locationManager(
    _ manager: CLLocationManager,
    didExitRegion region: CLRegion
  ) {

  }

  // MARK: - Monitoring failure

  func locationManager(
    _ manager: CLLocationManager,
    monitoringDidFailFor region: CLRegion?,
    withError error: Error
  ) {
  }
}