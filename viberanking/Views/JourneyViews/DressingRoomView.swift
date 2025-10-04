//
//  DressingRoomView.swift
//  viberanking
//
//  Created by Assistant on 2025/09/17.
//

import SwiftUI

struct DressingRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel = JourneyViewModel()
    
    let userId: String
    
    @State private var showingShare = false
    @State private var reportImage: UIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            content
        }
        .navigationTitle("Dressing Room")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) { Image(systemName: "chevron.left").foregroundColor(.white) }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await exportReport() } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }.foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingShare) {
            if let img = reportImage {
                ShareSheet(activityItems: [img])
            }
        }
        .task {
            await viewModel.loadUserJourney(userId: userId)
            await viewModel.evaluateLatestPhotoIfPossible()
            await viewModel.analyzeOutfitForLatestPhoto()
        }
    }
    
    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                photoWithOverlays
                insights
            }
            .padding(.bottom, 40)
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("AI Dressing Room")
                .font(.title2).bold().foregroundColor(.white)
            if let score = viewModel.outfitEvaluation?.overallScore {
                Text(String(format: "Overall Score: %.0f", score)).foregroundColor(.white.opacity(0.8))
            } else {
                Text("Analyzing...").foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.top, 16)
    }
    
    private var photoWithOverlays: some View {
        Group {
            if let url = viewModel.latestPhotoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        ZStack {
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(16)
                            if let eval = viewModel.outfitEvaluation {
                                DressingRoomOverlay(
                                    annotations: eval.highlights + eval.improvements,
                                    imageSize: .zero // size resolved in overlay using GeometryReader
                                ).allowsHitTesting(false)
                            }
                        }
                        .padding(.horizontal, 16)
                    case .failure(_):
                        placeholder("Failed to load image")
                    case .empty:
                        placeholder("Loading image...")
                    @unknown default:
                        placeholder("Loading...")
                    }
                }
            } else {
                placeholder("No photo available")
            }
        }
    }
    
    private var insights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline).foregroundColor(.white)
            if let hs = viewModel.outfitEvaluation?.highlights, !hs.isEmpty {
                ForEach(hs) { a in row(label: a.label, color: .green) }
            } else {
                Text("None").foregroundColor(.gray)
            }
            Divider().background(Color.white.opacity(0.1))
            Text("Improvements")
                .font(.headline).foregroundColor(.white)
            if let imps = viewModel.outfitEvaluation?.improvements, !imps.isEmpty {
                ForEach(imps) { a in row(label: a.label, color: .orange) }
            } else {
                Text("None").foregroundColor(.gray)
            }
            if let notes = viewModel.outfitEvaluation?.summaryNotes, !notes.isEmpty {
                Divider().background(Color.white.opacity(0.1))
                Text("Summary")
                    .font(.headline).foregroundColor(.white)
                ForEach(notes, id: \.self) { n in Text(n).foregroundColor(.gray) }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 16)
    }
    
    private func row(label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundColor(.white)
            Spacer()
        }
    }
    
    private func placeholder(_ text: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1))
            Text(text).foregroundColor(.gray)
        }
        .frame(height: 240)
        .padding(.horizontal, 16)
    }
    
    // Export the full screen section as an image to share
    private func exportReport() async {
        let renderer = ImageRenderer(content: content.background(Color.black))
        if let uiImage = renderer.uiImage {
            await MainActor.run {
                self.reportImage = uiImage
                self.showingShare = true
            }
        }
    }
}

// Simple ShareSheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


