import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var alertEngine: CameraAlertEngine
    @EnvironmentObject var alertManager: AlertManager
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Map
            Map {
                ForEach(alertEngine.cameras) { camera in
                    // Enforcement zone segment line
                    MapPolyline(coordinates: [
                        camera.segmentStartCoordinate,
                        camera.segmentEndCoordinate
                    ])
                    .stroke(zoneColor(for: camera), lineWidth: 5)

                    // Warning radius circle
                    MapCircle(
                        center: camera.coordinate,
                        radius: CameraAlertEngine.approachRadiusMeters
                    )
                    .foregroundStyle(zoneColor(for: camera).opacity(0.08))
                    .stroke(zoneColor(for: camera).opacity(0.3), lineWidth: 1)

                    // Camera marker
                    Marker(
                        camera.street,
                        systemImage: "camera.fill",
                        coordinate: camera.coordinate
                    )
                    .tint(zoneColor(for: camera))
                }

                UserAnnotation()
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }

            // Alert overlay
            VStack {
                // Status bar
                statusBar

                Spacer()

                // Active alert banner
                if let alert = alertEngine.activeAlert {
                    alertBanner(alert)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: alertEngine.activeAlert)
        }
        .onAppear {
            locationManager.requestPermissions()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            // Speed
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(locationManager.currentSpeedMPH))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("mph")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Driving status
            HStack(spacing: 6) {
                Circle()
                    .fill(locationManager.isDriving ? .green : .gray)
                    .frame(width: 8, height: 8)
                Text(locationManager.isDriving ? "Driving" : "Not Driving")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Nearest camera
            if let distance = alertEngine.nearestCameraDistance {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedDistance(distance))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text("nearest camera")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Settings
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gear")
                    .font(.title3)
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Alert Banner

    private func alertBanner(_ alert: CameraAlert) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: alert.level == .speeding ? "exclamationmark.triangle.fill" : "camera.fill")
                    .font(.title2)
                Text(alert.level.description)
                    .font(.headline)
            }

            Text("\(alert.camera.street) — \(alert.camera.segment)")
                .font(.subheadline)

            HStack(spacing: 16) {
                Label("\(Int(alert.currentSpeedMPH)) mph", systemImage: "speedometer")
                Label("Limit \(alert.camera.speedLimitMPH)", systemImage: "gauge.with.dots.needle.33percent")
            }
            .font(.subheadline)

            if alertManager.showFineEstimates, let fine = alert.fineEstimate {
                Text("Potential fine: \(fine)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(backgroundColor(for: alert.level), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func backgroundColor(for level: AlertLevel) -> Color {
        switch level {
        case .speeding: return .red
        case .nearCamera: return .orange
        case .approaching: return .yellow.opacity(0.9)
        }
    }

    private func zoneColor(for camera: SpeedCamera) -> Color {
        guard let alert = alertEngine.activeAlert, alert.camera.id == camera.id else {
            return .red
        }
        switch alert.level {
        case .speeding: return .red
        case .nearCamera: return .orange
        case .approaching: return .yellow
        }
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        }
        return String(format: "%.1fkm", meters / 1000)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(CameraAlertEngine())
        .environmentObject(AlertManager())
}
