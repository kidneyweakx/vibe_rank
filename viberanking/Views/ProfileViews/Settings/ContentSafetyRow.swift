import SwiftUI

struct ContentSafetyRow: View {
    var body: some View {
        SettingsRow(
            icon: "eye.slash.fill",
            title: "Content Safety",
            action: {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    let hosting = UIHostingController(rootView: LanguageSettingsView())
                    hosting.modalPresentationStyle = .formSheet
                    rootVC.present(hosting, animated: true)
                }
            }
        )
    }
}

#Preview {
    ContentSafetyRow()
}


