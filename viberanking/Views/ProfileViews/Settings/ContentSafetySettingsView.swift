import SwiftUI

struct ContentSafetySettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Sensitive Content")) {
                SafetyBlurToggleRow()
            }
            Section(footer: Text("You can tap & hold a photo to reveal it once.").font(.footnote)) {
                EmptyView()
            }
        }
        .navigationTitle("Content Safety")
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NavigationView { ContentSafetySettingsView() }
}


