//
//  PrivacyPolicyView.swift
//  viberanking
//
//  Created by AI on 2025/08/10.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Privacy Policy")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Last Updated: August 10, 2025")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Group {
                            Text("Welcome to Ninja Plus! We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our services, including our API, website, and related platforms.")
                                .foregroundColor(.gray)
                                .font(.body)
                        }
                        
                        PolicySection(title: "1. Information We Collect", bullets: [
                            "Account Data: Username, email, and profile details when you register.",
                            "Usage Data: IP address, device information, browser type, and interactions with our services.",
                            "API Data: Requests made to our API, including timestamps and endpoints accessed.",
                            "Cookies & Tracking: We use cookies to enhance user experience and analyze service performance."
                        ])
                        
                        PolicySection(title: "2. How We Use Your Data", bullets: [
                            "Provide, maintain, and improve Ninja Plus services.",
                            "Monitor API usage and prevent abuse.",
                            "Respond to inquiries and offer customer support.",
                            "Comply with legal obligations and enforce our terms."
                        ])
                        
                        PolicySection(title: "3. Data Sharing & Disclosure", bullets: [
                            "We do not sell your personal data. However, we may share it with:",
                            "Service Providers: Trusted third parties assisting in operations (e.g., hosting, analytics).",
                            "Legal Compliance: If required by law or to protect our rights and safety."
                        ])
                        
                        PolicySection(title: "4. Data Security", bullets: [
                            "We implement industry-standard measures (encryption, access controls) to protect your data. However, no system is 100% secure—please use strong passwords and report suspicious activity."
                        ])
                        
                        PolicySection(title: "5. Your Rights", bullets: [
                            "Access, correct, or delete your personal data.",
                            "Opt out of marketing communications.",
                            "Request data portability or restrict processing.",
                            "Contact us at [Your Contact Email] to exercise these rights."
                        ])
                        
                        PolicySection(title: "6. Third-Party Links", bullets: [
                            "Our services may link to external sites. We are not responsible for their privacy practices—review their policies separately."
                        ])
                        
                        PolicySection(title: "7. Changes to This Policy", bullets: [
                            "We may update this policy periodically. Continued use of Ninja Plus after changes constitutes acceptance."
                        ])
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct PolicySection: View {
    let title: String
    let bullets: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
            .font(.headline)
            .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(bullets, id: \.self) { item in
                    Text(item)
                        .font(.body)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    PrivacyPolicyView()
}


