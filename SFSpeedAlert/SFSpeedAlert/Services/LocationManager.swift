import Foundation
import CoreLocation
import CoreMotion
import Combine

final class LocationManager: NSObject, ObservableObject {
    private let clManager = CLLocationManager()
    private let activityManager = CMMotionActivityManager()

    @Published var currentLocation: CLLocation?
    @Published var currentSpeedMPH: Double = 0
    @Published var isDriving: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        clManager.distanceFilter = 5 // Update every 5 meters
        clManager.allowsBackgroundLocationUpdates = true
        clManager.showsBackgroundLocationIndicator = true
        clManager.activityType = .automotiveNavigation
    }

    func requestPermissions() {
        clManager.requestAlwaysAuthorization()
    }

    func startTracking() {
        clManager.startUpdatingLocation()
        startActivityDetection()
    }

    func stopTracking() {
        clManager.stopUpdatingLocation()
        activityManager.stopActivityUpdates()
    }

    private func startActivityDetection() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity else { return }
            self?.isDriving = activity.automotive
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // CLLocation.speed is in m/s; convert to mph
        // Negative speed means invalid
        let speedMPS = max(location.speed, 0)
        currentSpeedMPH = speedMPS * 2.23694

        currentLocation = location
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedAlways ||
           manager.authorizationStatus == .authorizedWhenInUse {
            startTracking()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
