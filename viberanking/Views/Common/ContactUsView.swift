//
//  ContactUsView.swift
//  viberanking
//
//  Created by AI on 2025/08/10.
//

import SwiftUI

struct ContactUsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("contact.title".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("contact.subtitle".localized)
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("contact.email".localized)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("contact.email.address".localized)
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("contact.twitter".localized)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("contact.twitter.handle".localized)
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("contact.business".localized)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("contact.business.address".localized)
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

#Preview {
    ContactUsView()
}


