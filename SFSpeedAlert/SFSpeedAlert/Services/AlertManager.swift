import Foundation
import UserNotifications
import AVFoundation

final class AlertManager: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenAlert: CameraAlert?
    private var lastSpokenTime: Date = .distantPast

    /// Minimum seconds between repeated spoken alerts of the same level
    private static let cooldownSeconds: TimeInterval = 15

    @Published var showFineEstimates: Bool = false

    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error {
                print("Notification permission error: \(error)")
            }
        }
        configureAudioSession()
    }

    func deliver(_ alert: CameraAlert) {
        sendNotification(for: alert)
        speak(alert)
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    // MARK: - Spoken Alerts

    private func speak(_ alert: CameraAlert) {
        // Cooldown: don't repeat the same alert level too quickly
        if alert == lastSpokenAlert,
           Date().timeIntervalSince(lastSpokenTime) < Self.cooldownSeconds {
            return
        }

        synthesizer.stopSpeaking(at: .immediate)

        let message = spokenMessage(for: alert)
        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0

        switch alert.level {
        case .speeding:
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.1
        case .nearCamera:
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        case .approaching:
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
            utterance.volume = 0.8
        }

        synthesizer.speak(utterance)
        lastSpokenAlert = alert
        lastSpokenTime = Date()
    }

    private func spokenMessage(for alert: CameraAlert) -> String {
        let camera = alert.camera
        let speed = Int(alert.currentSpeedMPH)

        switch alert.level {
        case .speeding:
            var msg = "Warning! Speed camera ahead on \(camera.street). You are going \(speed) in a \(camera.speedLimitMPH) zone. Slow down."
            if showFineEstimates, let fine = alert.fineEstimate {
                msg += " Potential fine: \(fine)."
            }
            return msg
        case .nearCamera:
            return "Speed camera zone. \(camera.street). Limit is \(camera.speedLimitMPH)."
        case .approaching:
            let distance = Int(alert.distanceMeters)
            return "Camera ahead in \(distance) meters on \(camera.street). Limit \(camera.speedLimitMPH)."
        }
    }

    // MARK: - Push Notifications

    private func sendNotification(for alert: CameraAlert) {
        let content = UNMutableNotificationContent()
        let camera = alert.camera

        switch alert.level {
        case .speeding:
            content.title = "SLOW DOWN"
            content.body = "\(Int(alert.currentSpeedMPH)) mph in a \(camera.speedLimitMPH) mph zone on \(camera.street)"
            if showFineEstimates, let fine = alert.fineEstimate {
                content.body += " — Fine: \(fine)"
            }
            content.sound = .defaultCritical
            content.interruptionLevel = .critical
        case .nearCamera:
            content.title = "Speed Camera Zone"
            content.body = "\(camera.street) — Limit \(camera.speedLimitMPH) mph"
            content.sound = .default
            content.interruptionLevel = .timeSensitive
        case .approaching:
            content.title = "Camera Ahead"
            content.body = "\(camera.street) in \(Int(alert.distanceMeters))m — Limit \(camera.speedLimitMPH) mph"
            content.sound = .default
            content.interruptionLevel = .active
        }

        let request = UNNotificationRequest(
            identifier: "camera-\(camera.id)-\(alert.level)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request)
    }
}
