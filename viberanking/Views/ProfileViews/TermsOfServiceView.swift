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
                            Text("tos.title".localized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("policy.last_updated".localized(with: "August 9, 2025"))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // Introduction
                        VStack(alignment: .leading, spacing: 12) {
                            Text("tos.intro".localized)
                                .font(.body)
                                .foregroundColor(.white)
                        }
                        
                        // Section 1
                        TermsSection(
                            title: "tos.section1.title".localized,
                            content: [
                                "tos.section1.b1".localized,
                                "tos.section1.b2".localized,
                                "tos.section1.b3".localized
                            ]
                        )
                        
                        // Section 2
                        TermsSection(
                            title: "tos.section2.title".localized,
                            content: [
                                "tos.section2.b0".localized,
                                "tos.section2.b1".localized,
                                "tos.section2.b2".localized,
                                "tos.section2.b3".localized,
                                "tos.section2.b4".localized,
                                "tos.section2.b5".localized
                            ]
                        )

                        // No Tolerance Policy (explicit per Guideline 1.2)
                        TermsSection(
                            title: "No Tolerance Policy for Objectionable Content",
                            content: [
                                "By using this app, you agree to our strict no-tolerance policy for objectionable content and abusive behavior. Content that is sexual, violent, hateful, harassing, discriminatory, illegal, or otherwise inappropriate is strictly prohibited. Reports are reviewed within 24 hours and offending content will be removed. Offending users may be ejected."
                            ]
                        )
                        
                        // Section 3
                        TermsSection(
                            title: "tos.section3.title".localized,
                            content: [
                                "tos.section3.b1".localized,
                                "tos.section3.b2".localized,
                                "tos.section3.b3".localized,
                                "tos.section3.b4".localized,
                                "tos.section3.b5".localized
                            ]
                        )
                        
                        // Section 4
                        TermsSection(
                            title: "tos.section4.title".localized,
                            content: [
                                "tos.section4.b1".localized,
                                "tos.section4.b2".localized,
                                "tos.section4.b3".localized,
                                "tos.section4.b4".localized
                            ]
                        )
                        
                        // Section 5
                        TermsSection(
                            title: "tos.section5.title".localized,
                            content: [
                                "tos.section5.b1".localized,
                                "tos.section5.b2".localized,
                                "tos.section5.b3".localized
                            ]
                        )
                        
                        // Section 6
                        TermsSection(
                            title: "tos.section6.title".localized,
                            content: [
                                "tos.section6.b1".localized,
                                "tos.section6.b2".localized,
                                "tos.section6.b3".localized,
                                "tos.section6.b4".localized
                            ]
                        )
                        
                        // Section 7
                        TermsSection(
                            title: "tos.section7.title".localized,
                            content: [
                                "tos.section7.b1".localized,
                                "tos.section7.b2".localized,
                                "tos.section7.b3".localized
                            ]
                        )
                        
                        // Section 8
                        TermsSection(
                            title: "tos.section8.title".localized,
                            content: [
                                "tos.section8.b1".localized,
                                "tos.section8.b2".localized,
                                "tos.section8.b3".localized
                            ]
                        )
                        
                        // Section 9
                        TermsSection(
                            title: "tos.section9.title".localized,
                            content: [
                                "tos.section9.b1".localized
                            ]
                        )
                        
                        // Section 10
                        TermsSection(
                            title: "tos.section10.title".localized,
                            content: [
                                "tos.section10.b1".localized,
                                "tos.section10.b2".localized,
                                "tos.section10.b3".localized
                            ]
                        )
                        
                        // Section 11
                        TermsSection(
                            title: "tos.section11.title".localized,
                            content: [
                                "tos.section11.b1".localized
                            ]
                        )
                        
                        // Contact
                        VStack(alignment: .leading, spacing: 12) {
                            Text("contact.title".localized)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("tos.contact".localized)
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
                    Button("common.done".localized) {
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