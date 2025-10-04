//
//  AIPhotoEvaluator.swift
//  viberanking
//
//  Created by Assistant on 2025/09/17.
//

import Foundation
import Vision
import UIKit

// MARK: - AI Photo Evaluation Result
struct AIPhotoEvaluation {
    let score: Double          // 0 - 100
    let isHandsome: Bool       // Heuristic based on score
    let confidence: Double     // 0 - 1
    let faceCount: Int
    let notes: [String]
}

// MARK: - AI Outfit Annotations & Evaluation
struct AIAnnotation: Identifiable {
    enum Category: String { case highlight, improve }
    let id = UUID()
    let category: Category
    let label: String
    /// Normalized Vision bounding box (0..1, origin at bottom-left)
    let boundingBox: CGRect
}

struct AIOutfitEvaluation {
    let overallScore: Double       // 0 - 100
    let highlights: [AIAnnotation]
    let improvements: [AIAnnotation]
    let summaryNotes: [String]
}

// MARK: - AI Photo Evaluator
final class AIPhotoEvaluator {
    // Simple singleton for convenience
    static let shared = AIPhotoEvaluator()
    private init() {}
    
    /// Evaluate if the person in the photo looks handsome using Vision heuristics.
    /// - Parameter imageURL: Remote image URL to analyze.
    /// - Returns: `AIPhotoEvaluation` with score and details.
    func evaluate(imageURL: URL) async throws -> AIPhotoEvaluation {
        let (data, _) = try await URLSession.shared.data(from: imageURL)
        guard let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage else {
            throw AppError.invalidImageFormat
        }
        
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        // Requests
        let faceRectanglesRequest = VNDetectFaceRectanglesRequest()
        let faceQualityRequest = VNDetectFaceCaptureQualityRequest()
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([faceRectanglesRequest, faceQualityRequest])
        
        // Extract results
        let observations = (faceRectanglesRequest.results as? [VNFaceObservation]) ?? []
        let faceCount = observations.count
        
        // Map quality values. Vision quality is 0..1 on iOS 15+, may be nil.
        let qualityValues: [Double] = observations.compactMap { $0.faceCaptureQuality.map { Double($0) } }
        let averageQuality = qualityValues.isEmpty ? 0.0 : (qualityValues.reduce(0, +) / Double(qualityValues.count))
        
        // Compute approximate face coverage (sum of face areas / image area)
        let totalFaceAreaRatio: Double = observations.reduce(0.0) { partial, obs in
            // VNFaceObservation boundingBox is normalized in unit coordinates with origin bottom-left
            let rect = obs.boundingBox
            let width = rect.width * imageWidth
            let height = rect.height * imageHeight
            let area = width * height
            let imageArea = imageWidth * imageHeight
            return partial + Double(area / imageArea)
        }
        
        // Heuristic scoring
        // - Prefer a single, clear face
        // - Higher capture quality → higher score
        // - Reasonable face size in frame → higher score
        // - Penalize multiple faces
        let singleFaceBonus: Double = (faceCount == 1) ? 0.1 : 0.0
        let multiFacePenalty: Double = (faceCount > 1) ? min(0.2, Double(faceCount - 1) * 0.1) : 0.0
        
        // Weight components
        let qualityComponent = max(0.0, min(1.0, averageQuality))               // 0..1
        let sizeComponent = max(0.0, min(1.0, totalFaceAreaRatio * 2.0))        // 0..~ → clamp to 0..1, ideal ~0.3-0.5 face coverage
        
        var rawScore = 0.7 * qualityComponent + 0.3 * sizeComponent + singleFaceBonus - multiFacePenalty
        rawScore = max(0.0, min(1.0, rawScore))
        let score100 = rawScore * 100.0
        
        // Classify
        let threshold: Double = 60.0
        let isHandsome = score100 >= threshold
        
        // Build notes
        var notes: [String] = []
        if faceCount == 0 { notes.append("No face detected") }
        if faceCount > 1 { notes.append("Multiple faces detected") }
        if averageQuality < 0.5 { notes.append("Low face capture quality") }
        if totalFaceAreaRatio < 0.05 { notes.append("Face too small in frame") }
        if notes.isEmpty { notes.append("Clear face and decent framing") }
        
        // Confidence loosely tied to quality
        let confidence = max(0.1, min(1.0, averageQuality + 0.2))
        
        return AIPhotoEvaluation(
            score: score100,
            isHandsome: isHandsome,
            confidence: confidence,
            faceCount: faceCount,
            notes: notes
        )
    }

    /// Analyze outfit and framing with Vision: faces, human rectangles, pose, and simple color contrast.
    func analyzeOutfit(imageURL: URL) async throws -> AIOutfitEvaluation {
        let (data, _) = try await URLSession.shared.data(from: imageURL)
        guard let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage else {
            throw AppError.invalidImageFormat
        }
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        let faceRequest = VNDetectFaceRectanglesRequest()
        let faceQuality = VNDetectFaceCaptureQualityRequest()
        let humanRequest = VNDetectHumanRectanglesRequest()
        let poseRequest = VNDetectHumanBodyPoseRequest()
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([faceRequest, faceQuality, humanRequest, poseRequest])
        
        let faces = (faceRequest.results as? [VNFaceObservation]) ?? []
        let humans = (humanRequest.results as? [VNHumanObservation]) ?? []
        let poses = (poseRequest.results as? [VNHumanBodyPoseObservation]) ?? []
        
        var highlights: [AIAnnotation] = []
        var improvements: [AIAnnotation] = []
        var summary: [String] = []
        
        let primary = humans.first?.boundingBox ?? faces.first?.boundingBox
        if let p = primary {
            highlights.append(AIAnnotation(category: .highlight, label: "Subject detected", boundingBox: p))
        } else {
            improvements.append(AIAnnotation(category: .improve, label: "No subject detected", boundingBox: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2)))
        }
        
        let avgQuality: Double = {
            let q = faces.compactMap { $0.faceCaptureQuality.map { Double($0) } }
            guard !q.isEmpty else { return 0 }
            return q.reduce(0, +) / Double(q.count)
        }()
        if let f = faces.first {
            if avgQuality >= 0.6 {
                highlights.append(AIAnnotation(category: .highlight, label: "Clear face", boundingBox: f.boundingBox))
            } else {
                improvements.append(AIAnnotation(category: .improve, label: "Improve face lighting", boundingBox: f.boundingBox))
            }
        }
        
        var contrastScore: Double = 0.5
        if let person = humans.first {
            // Approximate torso region: inside human box below face
            let h = person.boundingBox
            if let f = faces.first {
                let fRect = f.boundingBox
                let torsoY = max(h.minY, fRect.minY - (h.height * 0.25))
                let torsoHeight = max(0.0, (fRect.minY - h.minY))
                let torsoRect = CGRect(x: h.minX + h.width * 0.15, y: torsoY, width: h.width * 0.7, height: torsoHeight)
                let c = try computeContrast(in: cgImage, region: torsoRect)
                contrastScore = c
                if c > 0.25 {
                    highlights.append(AIAnnotation(category: .highlight, label: "Good outfit contrast", boundingBox: torsoRect))
                    summary.append("Outfit contrast: good")
                } else {
                    improvements.append(AIAnnotation(category: .improve, label: "Low outfit contrast", boundingBox: torsoRect))
                    summary.append("Outfit contrast: low")
                }
            } else {
                // Framing heuristic
                let coverage = Double(h.width * h.height)
                if coverage < 0.1 { improvements.append(AIAnnotation(category: .improve, label: "Subject too small", boundingBox: h)) }
                else { highlights.append(AIAnnotation(category: .highlight, label: "Good framing", boundingBox: h)) }
            }
        }
        
        if let pose = poses.first, let pts = try? pose.recognizedPoints(.all) {
            let ls = pts[.leftShoulder]?.location
            let rs = pts[.rightShoulder]?.location
            if let ls, let rs {
                let d = abs(ls.y - rs.y)
                if d < 0.05 { summary.append("Shoulder alignment: good") }
                else { summary.append("Shoulder alignment: uneven") }
            }
        }
        
        // Aggregate score
        let coverageScore: Double = {
            guard let b = primary else { return 0.4 }
            return min(1.0, max(0.2, Double(b.width * b.height * 1.5)))
        }()
        let qualityScore = max(0.0, min(1.0, avgQuality))
        let finalRaw = max(0.0, min(1.0, 0.5 * qualityScore + 0.3 * contrastScore + 0.2 * coverageScore))
        if highlights.isEmpty && improvements.isEmpty { summary.append("No significant features detected") }
        
        return AIOutfitEvaluation(
            overallScore: finalRaw * 100.0,
            highlights: highlights,
            improvements: improvements,
            summaryNotes: summary
        )
    }

    // MARK: - Helpers
    private func computeContrast(in cgImage: CGImage, region: CGRect) throws -> Double {
        // Convert normalized Vision rect (origin bottom-left) to pixel rect (origin top-left)
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        let pixelRect = CGRect(x: region.minX * w, y: (1.0 - region.maxY) * h, width: region.width * w, height: region.height * h).integral
        guard let cropped = cgImage.cropping(to: pixelRect) else { return 0.0 }
        let targetSize = CGSize(width: 64, height: 64)
        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1)
        UIImage(cgImage: cropped).draw(in: CGRect(origin: .zero, size: targetSize))
        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = scaled, let sample = image.cgImage else { return 0.0 }
        guard let ctx = CGContext(data: nil, width: sample.width, height: sample.height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return 0.0 }
        ctx.draw(sample, in: CGRect(x: 0, y: 0, width: sample.width, height: sample.height))
        guard let buffer = ctx.data else { return 0.0 }
        let ptr = buffer.bindMemory(to: UInt8.self, capacity: sample.width * sample.height * 4)
        var sumBright = (r: 0.0, g: 0.0, b: 0.0, c: 0.0)
        var sumDark = (r: 0.0, g: 0.0, b: 0.0, c: 0.0)
        for y in 0..<sample.height {
            for x in 0..<sample.width {
                let i = (y * sample.width + x) * 4
                let r = Double(ptr[i]) / 255.0
                let g = Double(ptr[i+1]) / 255.0
                let b = Double(ptr[i+2]) / 255.0
                let lum = 0.2126*r + 0.7152*g + 0.0722*b
                if lum > 0.5 { sumBright.r += r; sumBright.g += g; sumBright.b += b; sumBright.c += 1 }
                else { sumDark.r += r; sumDark.g += g; sumDark.b += b; sumDark.c += 1 }
            }
        }
        guard sumBright.c > 0 && sumDark.c > 0 else { return 0.0 }
        let br = sumBright.r / sumBright.c, bg = sumBright.g / sumBright.c, bb = sumBright.b / sumBright.c
        let dr = sumDark.r / sumDark.c, dg = sumDark.g / sumDark.c, db = sumDark.b / sumDark.c
        let distance = sqrt(pow(br - dr, 2) + pow(bg - dg, 2) + pow(bb - db, 2))
        return min(1.0, distance)
    }
}


