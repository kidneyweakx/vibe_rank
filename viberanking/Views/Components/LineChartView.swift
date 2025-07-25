import SwiftUI

struct LineChartView: View {
    let data: [Double]
    let gradient = Gradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0)])
    
    @State private var selectedIndex: Int?
    @State private var dragLocation: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            let path = Path.quadCurvedPath(with: data, in: geometry.frame(in: .local))
            
            path
                .fill(LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom))
            
            path
                .stroke(Color.blue, lineWidth: 2)

            if let location = dragLocation {
                let (index, point) = findClosestPoint(at: location, in: geometry.size)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                    .position(point)
                
                Text(String(format: "%.2f", data[index]))
                    .position(x: point.x, y: point.y - 20)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    self.dragLocation = value.location
                }
                .onEnded { _ in
                    self.dragLocation = nil
                }
        )
    }

    private func findClosestPoint(at location: CGPoint, in size: CGSize) -> (Int, CGPoint) {
        let stepX = size.width / CGFloat(data.count - 1)
        let index = Int(round(location.x / stepX))
        let clampedIndex = max(0, min(data.count - 1, index))
        
        let x = CGFloat(clampedIndex) * stepX
        let y = (1 - CGFloat(data[clampedIndex])) * size.height
        
        return (clampedIndex, CGPoint(x: x, y: y))
    }
}

extension Path {
    static func quadCurvedPath(with points: [Double], in rect: CGRect) -> Path {
        var path = Path()
        
        guard !points.isEmpty else { return path }
        
        let stepX = rect.width / CGFloat(points.count - 1)
        var p1 = CGPoint(x: 0, y: (1 - points[0]) * Double(rect.height))
        path.move(to: p1)
        
        if points.count == 1 {
            path.addLine(to: p1)
            return path
        }
        
        for i in 1..<points.count {
            let p2 = CGPoint(x: CGFloat(i) * stepX, y: (1 - points[i]) * Double(rect.height))
            let midPoint = CGPoint.midPoint(p1: p1, p2: p2)
            path.addQuadCurve(to: midPoint, control: CGPoint.controlPoint(p1: midPoint, p2: p1))
            path.addQuadCurve(to: p2, control: CGPoint.controlPoint(p1: midPoint, p2: p2))
            p1 = p2
        }
        return path
    }
}

extension CGPoint {
    static func midPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    static func controlPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        var controlPoint = CGPoint.midPoint(p1: p1, p2: p2)
        let diffY = abs(p2.y - controlPoint.y)
        
        if p1.y < p2.y {
            controlPoint.y += diffY
        } else {
            controlPoint.y -= diffY
        }
        
        return controlPoint
    }
}

struct LineChartView_Previews: PreviewProvider {
    static var previews: some View {
        LineChartView(data: [0.2, 0.4, 0.3, 0.6, 0.5, 0.8, 0.7])
            .frame(height: 200)
            .padding()
    }
}
