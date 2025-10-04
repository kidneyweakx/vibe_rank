//
//  QRCodeShareView.swift
//  viberanking
//
//  Created by Kiro on 2025/08/09.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeShareView: View {
    let userId: String
    @Binding var isPresented: Bool
    @State private var qrCodeImage: UIImage?
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack {
                Spacer()
                
                // QR Code Card
                VStack(spacing: 24) {
                    // Header with close button
                    HStack {
                        Text("profile.share_profile".localized)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // QR Code
                    if let qrImage = qrCodeImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .background(Color.white)
                            .cornerRadius(16)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .frame(width: 200, height: 200)
                            .overlay(
                                ProgressView()
                                    .tint(.black)
                            )
                    }
                    
                    Text("profile.scan_to_view".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Share button
                    Button {
                        shareQRCode()
                    } label: {
                        Text("profile.share_qr_code".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(25)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        let profileURL = "https://viberank.xyz/profile/\(userId)"
        let data = Data(profileURL.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
    
    private func shareQRCode() {
        guard let qrImage = qrCodeImage else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [qrImage],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

#Preview {
    QRCodeShareView(userId: "123", isPresented: .constant(true))
}