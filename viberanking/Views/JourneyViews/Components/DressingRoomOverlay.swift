//
//  DressingRoomOverlay.swift
//  viberanking
//
//  Created by Assistant on 2025/09/17.
//

import SwiftUI

/// Draws Vision-style normalized boxes over an image with labels.
struct DressingRoomOverlay: View {
    let annotations: [AIAnnotation]
    let imageSize: CGSize
    
    var body: some View {
        ZStack {
            ForEach(annotations) { ann in
                GeometryReader { geo in
                    let rect = convert(ann.boundingBox, in: geo.size)
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .stroke(ann.category == .highlight ? Color.green : Color.orange, lineWidth: 2)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                        Text(ann.label)
                            .font(.caption2)
                            .padding(4)
                            .background((ann.category == .highlight ? Color.green : Color.orange).opacity(0.8))
                            .foregroundColor(.black)
                            .cornerRadius(6)
                            .position(x: rect.minX + 4, y: rect.minY + 8)
                    }
                }
            }
        }
    }
}

private extension DressingRoomOverlay {
    /// Convert Vision normalized rect (origin bottom-left) to SwiftUI Geometry space (origin top-left)
    func convert(_ bbox: CGRect, in size: CGSize) -> CGRect {
        let x = bbox.minX * size.width
        let y = (1.0 - bbox.maxY) * size.height
        let w = bbox.width * size.width
        let h = bbox.height * size.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
}


