import Foundation
import CoreLocation
import Combine

final class CameraAlertEngine: ObservableObject {
    /// Radius in meters to start warning the driver they're approaching a camera
    static let approachRadiusMeters: Double = 500
    /// Radius in meters for "in the camera zone"
    static let zoneRadiusMeters: Double = 150

    @Published var cameras: [SpeedCamera] = []
    @Published var activeAlert: CameraAlert?
    @Published var nearestCamera: SpeedCamera?
    @Published var nearestCameraDistance: Double?

    /// Tracks the last alert to avoid repeating the same one
    private var lastDeliveredAlert: CameraAlert?

    func loadCameras() {
        guard let url = Bundle.main.url(forResource: "sf_speed_cameras", withExtension: "json") else {
            print("Camera data file not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(SpeedCameraFile.self, from: data)
            cameras = file.cameras
        } catch {
            print("Failed to load camera data: \(error)")
        }
    }

    func evaluate(location: CLLocation, speedMPH: Double, isDriving: Bool) {
        guard isDriving, !cameras.isEmpty else {
            activeAlert = nil
            nearestCamera = nil
            nearestCameraDistance = nil
            return
        }

        var closestCamera: SpeedCamera?
        var closestDistance: Double = .greatestFiniteMagnitude

        for camera in cameras {
            let distance = distanceToEnforcementZone(from: location, camera: camera)
            if distance < closestDistance {
                closestDistance = distance
                closestCamera = camera
            }
        }

        nearestCamera = closestCamera
        nearestCameraDistance = closestDistance

        guard let camera = closestCamera else { return }

        let alert: CameraAlert?

        if closestDistance <= Self.zoneRadiusMeters {
            // In the enforcement zone
            if speedMPH >= Double(camera.citationThresholdMPH) {
                alert = CameraAlert(
                    camera: camera,
                    level: .speeding,
                    currentSpeedMPH: speedMPH,
                    distanceMeters: closestDistance
                )
            } else {
                alert = CameraAlert(
                    camera: camera,
                    level: .nearCamera,
                    currentSpeedMPH: speedMPH,
                    distanceMeters: closestDistance
                )
            }
        } else if closestDistance <= Self.approachRadiusMeters {
            // Approaching — gentle warning
            alert = CameraAlert(
                camera: camera,
                level: .approaching,
                currentSpeedMPH: speedMPH,
                distanceMeters: closestDistance
            )
        } else {
            alert = nil
        }

        // Only deliver if the alert changed
        if let alert, alert != lastDeliveredAlert {
            activeAlert = alert
            lastDeliveredAlert = alert
        } else if alert == nil {
            activeAlert = nil
            lastDeliveredAlert = nil
        }
    }

    /// Shortest distance from current location to the enforcement segment (start–end line)
    private func distanceToEnforcementZone(from location: CLLocation, camera: SpeedCamera) -> Double {
        let start = CLLocation(latitude: camera.segmentStart.lat, longitude: camera.segmentStart.lon)
        let end = CLLocation(latitude: camera.segmentEnd.lat, longitude: camera.segmentEnd.lon)
        let cameraLoc = CLLocation(latitude: camera.cameraLocation.lat, longitude: camera.cameraLocation.lon)

        // Use the minimum of: distance to camera, distance to segment start, distance to segment end,
        // and perpendicular distance to segment line
        let dCamera = location.distance(from: cameraLoc)
        let dStart = location.distance(from: start)
        let dEnd = location.distance(from: end)
        let dPerp = perpendicularDistance(point: location, lineStart: start, lineEnd: end)

        return min(dCamera, dStart, dEnd, dPerp)
    }

    /// Approximate perpendicular distance from a point to a line segment using flat-earth projection
    private func perpendicularDistance(point: CLLocation, lineStart: CLLocation, lineEnd: CLLocation) -> Double {
        let px = point.coordinate.longitude
        let py = point.coordinate.latitude
        let ax = lineStart.coordinate.longitude
        let ay = lineStart.coordinate.latitude
        let bx = lineEnd.coordinate.longitude
        let by = lineEnd.coordinate.latitude

        let dx = bx - ax
        let dy = by - ay
        let lenSq = dx * dx + dy * dy

        guard lenSq > 0 else {
            return point.distance(from: lineStart)
        }

        // Project point onto line, clamped to segment
        let t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / lenSq))
        let projLat = ay + t * dy
        let projLon = ax + t * dx
        let projected = CLLocation(latitude: projLat, longitude: projLon)

        return point.distance(from: projected)
    }
}
