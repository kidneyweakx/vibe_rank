import SwiftUI

struct ProgressBar: View {
    let value: Double
    let maxValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(.systemGray5))
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value / self.maxValue) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color.blue)
                    .animation(.linear)
            }
            .cornerRadius(5.0)
        }
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBar(value: 50, maxValue: 100)
            .frame(height: 10)
            .padding()
    }
}
