import SwiftUI

struct SafetyBlurToggleRow: View {
    @State private var isOn: Bool = UserDefaults.standard.bool(forKey: "safety_blur_enabled")

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Blur sensitive content")
                Text("Tap & hold on a photo to reveal once").font(.caption).foregroundColor(.secondary)
            }
        }
        .onChange(of: isOn) { newValue in
            UserDefaults.standard.set(newValue, forKey: "safety_blur_enabled")
        }
    }
}

#Preview {
    Form { SafetyBlurToggleRow() }
}


