import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var alertManager: AlertManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Alerts") {
                    Toggle("Show fine estimates", isOn: $alertManager.showFineEstimates)
                }

                Section("About") {
                    LabeledContent("Cameras Tracked", value: "33")
                    LabeledContent("Citation Threshold", value: "11+ mph over limit")
                    LabeledContent("Warning Radius", value: "500m")
                    LabeledContent("Zone Radius", value: "150m")
                }

                Section("Fine Schedule") {
                    LabeledContent("11–15 mph over", value: "$50")
                    LabeledContent("16–25 mph over", value: "$100")
                    LabeledContent("26+ mph over", value: "$200")
                    LabeledContent("School zone", value: "Up to $500")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
