//
//  TermsOfServiceView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vibe Ranking Terms of Service")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Last Updated: August 9, 2025")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // Introduction
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By accessing or using **Vibe Ranking**'s services (including our app, API, and related tools), you agree to comply with these Terms of Service (\"ToS\"). If you disagree, please refrain from using our services.")
                                .font(.body)
                                .foregroundColor(.white)
                        }
                        
                        // Section 1
                        TermsSection(
                            title: "1. Eligibility",
                            content: [
                                "You must be at least 13 years old (or the minimum age in your jurisdiction) to use Vibe Ranking.",
                                "Users must ensure compliance with these terms and all applicable laws.",
                                "By creating an account, you confirm that you meet these eligibility requirements."
                            ]
                        )
                        
                        // Section 2
                        TermsSection(
                            title: "2. Acceptable Use",
                            content: [
                                "You agree not to:",
                                "• Violate laws or infringe on others' rights (e.g., privacy, intellectual property)",
                                "• Abuse our services (e.g., excessive requests, bypassing rate limits)",
                                "• Distribute malware, spam, or harmful content",
                                "• Reverse-engineer, scrape, or disrupt Vibe Ranking services",
                                "• Upload inappropriate, offensive, or copyrighted content without permission"
                            ]
                        )
                        
                        // Section 3
                        TermsSection(
                            title: "3. Photo Upload and Rating System",
                            content: [
                                "Users may upload photos for rating by other users",
                                "All uploaded content must comply with our community guidelines",
                                "You retain ownership of your photos but grant us a license to display and process them",
                                "Ratings are subjective opinions and do not reflect absolute judgments",
                                "We reserve the right to remove content that violates our policies"
                            ]
                        )
                        
                        // Section 4
                        TermsSection(
                            title: "4. User Data and Privacy",
                            content: [
                                "We collect and process user data as described in our Privacy Policy",
                                "User preferences and demographic information help improve our services",
                                "You may request deletion of your account and associated data",
                                "We implement security measures to protect your personal information"
                            ]
                        )
                        
                        // Section 5
                        TermsSection(
                            title: "5. Intellectual Property",
                            content: [
                                "Vibe Ranking retains all rights to its software, branding, and content",
                                "You retain ownership of data you submit but grant us a license to process it for service operation",
                                "Users must respect intellectual property rights of others"
                            ]
                        )
                        
                        // Section 6
                        TermsSection(
                            title: "6. Premium Features and Payments",
                            content: [
                                "Some features may require payment or subscription",
                                "All purchases are processed through Apple's App Store",
                                "Refunds are subject to Apple's refund policy",
                                "Premium features may be modified or discontinued with notice"
                            ]
                        )
                        
                        // Section 7
                        TermsSection(
                            title: "7. Termination",
                            content: [
                                "We may suspend or terminate your access for violations, illegal activities, or threats to our infrastructure—with or without notice",
                                "You may terminate your account at any time through the app settings",
                                "Upon termination, your access to premium features will cease"
                            ]
                        )
                        
                        // Section 8
                        TermsSection(
                            title: "8. Disclaimers & Limitation of Liability",
                            content: [
                                "\"As Is\" Service: Vibe Ranking provides services without warranties (e.g., uptime, accuracy)",
                                "No Liability: We are not liable for indirect, incidental, or consequential damages arising from service use",
                                "Ratings and feedback are user opinions and do not constitute professional advice"
                            ]
                        )
                        
                        // Section 9
                        TermsSection(
                            title: "9. Indemnification",
                            content: [
                                "You agree to indemnify Vibe Ranking against claims related to your misuse of our services or violations of these terms"
                            ]
                        )
                        
                        // Section 10
                        TermsSection(
                            title: "10. Modifications",
                            content: [
                                "We may update these ToS periodically. Continued use after changes constitutes acceptance.",
                                "Check this page for updates.",
                                "Significant changes will be communicated through the app"
                            ]
                        )
                        
                        // Section 11
                        TermsSection(
                            title: "11. Governing Law",
                            content: [
                                "These terms are governed by the laws of Taiwan, and disputes will be resolved in its courts"
                            ]
                        )
                        
                        // Contact
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contact Us")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("If you have any questions about these Terms of Service, please contact us through the app's support feature.")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct TermsSection: View {
    let title: String
    let content: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(content, id: \.self) { text in
                    Text(text)
                        .font(.body)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    TermsOfServiceView()
}