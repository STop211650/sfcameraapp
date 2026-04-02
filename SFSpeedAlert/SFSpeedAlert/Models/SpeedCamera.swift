import Foundation
import CoreLocation

struct SpeedCamera: Identifiable, Codable {
    let id: Int
    let street: String
    let segment: String
    let speedLimitMPH: Int
    let district: Int
    let neighborhood: String
    let directionsMonitored: [String]
    let status: String
    let cameraAddress: String
    let cameraLocation: Coordinate
    let segmentStart: SegmentPoint
    let segmentEnd: SegmentPoint

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: cameraLocation.lat, longitude: cameraLocation.lon)
    }

    var segmentStartCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: segmentStart.lat, longitude: segmentStart.lon)
    }

    var segmentEndCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: segmentEnd.lat, longitude: segmentEnd.lon)
    }

    /// Citation threshold: speed limit + 11 mph
    var citationThresholdMPH: Int {
        speedLimitMPH + 11
    }

    enum CodingKeys: String, CodingKey {
        case id, street, segment, district, neighborhood, status
        case speedLimitMPH = "speed_limit_mph"
        case directionsMonitored = "directions_monitored"
        case cameraAddress = "camera_address"
        case cameraLocation = "camera_location"
        case segmentStart = "segment_start"
        case segmentEnd = "segment_end"
    }
}

struct Coordinate: Codable {
    let lat: Double
    let lon: Double
}

struct SegmentPoint: Codable {
    let intersection: String
    let lat: Double
    let lon: Double
}

struct SpeedCameraFile: Codable {
    let cameras: [SpeedCamera]
}

// MARK: - Alert Types

enum AlertLevel: Comparable {
    case approaching  // Within warning radius but not in enforcement zone
    case nearCamera   // In enforcement zone, speed OK
    case speeding     // In enforcement zone, 11+ mph over limit

    var description: String {
        switch self {
        case .approaching: return "Approaching Camera Zone"
        case .nearCamera: return "In Camera Zone"
        case .speeding: return "SPEED WARNING"
        }
    }
}

struct CameraAlert: Equatable {
    let camera: SpeedCamera
    let level: AlertLevel
    let currentSpeedMPH: Double
    let distanceMeters: Double

    static func == (lhs: CameraAlert, rhs: CameraAlert) -> Bool {
        lhs.camera.id == rhs.camera.id && lhs.level == rhs.level
    }

    var fineEstimate: String? {
        let over = currentSpeedMPH - Double(camera.speedLimitMPH)
        if over >= 26 {
            return "$200"
        } else if over >= 16 {
            return "$100"
        } else if over >= 11 {
            return "$50"
        }
        return nil
    }
}
