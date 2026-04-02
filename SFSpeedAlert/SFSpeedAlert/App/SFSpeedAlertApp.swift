import SwiftUI

@main
struct SFSpeedAlertApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var alertEngine = CameraAlertEngine()
    @StateObject private var alertManager = AlertManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(alertEngine)
                .environmentObject(alertManager)
                .onAppear {
                    alertManager.requestPermissions()
                    alertEngine.loadCameras()
                }
                .onReceive(locationManager.$currentLocation) { location in
                    guard let location else { return }
                    let speed = locationManager.currentSpeedMPH
                    let isDriving = locationManager.isDriving
                    alertEngine.evaluate(
                        location: location,
                        speedMPH: speed,
                        isDriving: isDriving
                    )
                }
                .onReceive(alertEngine.$activeAlert) { alert in
                    guard let alert else { return }
                    alertManager.deliver(alert)
                }
        }
    }
}
