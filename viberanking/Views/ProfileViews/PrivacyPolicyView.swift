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
                            Text("policy.privacy.title".localized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("policy.last_updated".localized(with: "August 10, 2025"))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Group {
                            Text("policy.privacy.intro".localized)
                                .foregroundColor(.gray)
                                .font(.body)
                        }
                        
                        PolicySection(title: "policy.privacy.section1.title".localized, bullets: [
                            "policy.privacy.section1.b1".localized,
                            "policy.privacy.section1.b2".localized,
                            "policy.privacy.section1.b3".localized,
                            "policy.privacy.section1.b4".localized
                        ])
                        
                        PolicySection(title: "policy.privacy.section2.title".localized, bullets: [
                            "policy.privacy.section2.b1".localized,
                            "policy.privacy.section2.b2".localized,
                            "policy.privacy.section2.b3".localized,
                            "policy.privacy.section2.b4".localized
                        ])
                        
                        PolicySection(title: "policy.privacy.section3.title".localized, bullets: [
                            "policy.privacy.section3.b1".localized,
                            "policy.privacy.section3.b2".localized,
                            "policy.privacy.section3.b3".localized
                        ])
                        
                        PolicySection(title: "policy.privacy.section4.title".localized, bullets: [
                            "policy.privacy.section4.b1".localized
                        ])
                        
                        PolicySection(title: "policy.privacy.section5.title".localized, bullets: [
                            "policy.privacy.section5.b1".localized,
                            "policy.privacy.section5.b2".localized,
                            "policy.privacy.section5.b3".localized,
                            "policy.privacy.section5.b4".localized
                        ])
                        
                        PolicySection(title: "policy.privacy.section6.title".localized, bullets: [
                            "policy.privacy.section6.b1".localized
                        ])
                        
                        PolicySection(title: "policy.privacy.section7.title".localized, bullets: [
                            "policy.privacy.section7.b1".localized
                        ])
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


