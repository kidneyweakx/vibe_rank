//
//  TrackingPrePromptView.swift
//  viberanking
//
//  Created by Assistant on 2025/09/17.
//

import SwiftUI

struct TrackingPrePromptView: View {
    let onContinue: () -> Void

    private var message: String {
        // Reuse the same localized copy shown by the system ATT dialog
        NSLocalizedString(
            "NSUserTrackingUsageDescription",
            tableName: "InfoPlist",
            bundle: .main,
            value: "",
            comment: "ATT purpose string reused for pre-prompt"
        )
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 52))
                .foregroundColor(.accentColor)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Neutral, non-coercive note for compliance
            Text("You can choose Allow or Ask App Not to Track. Your choice won’t affect core features, and you can change it anytime in Settings.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}

#if DEBUG
struct TrackingPrePromptView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingPrePromptView(onContinue: {})
    }
}
#endif


