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
                        Text("Contact Us")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("We'd love to hear from you. If you have questions, feedback, or need support, please reach out:")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("support@ninjaplus.app")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Twitter")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("@ninjaplusapp")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Business Inquiries")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("business@ninjaplus.app")
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
                    Button("Done") {
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


