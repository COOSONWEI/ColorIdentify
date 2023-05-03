import SwiftUI
import Charts

struct PieChartView: View {
    @State private var selectedSector: Int?
    let data: [(name: String, value: Double)]
    let colors: [Color]
    let lineWidth: CGFloat
    let labelFont: Font
    
    var body: some View {
        VStack {
            ZStack {
                ForEach(0..<data.count) { index in
                    SectorShape(startAngle: angle(for: index), endAngle: angle(for: index + 1))
                        .fill(colors[index])
                        .scaleEffect(selectedSector == index ? 1.1 : 1.0)
                        .animation(.spring())
                        .onTapGesture {
                            withAnimation {
                                if selectedSector == index {
                                    selectedSector = nil
                                } else {
                                    selectedSector = index
                                }
                            }
                        }
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .padding(8)
            
            if selectedSector != nil {
                Text("\(data[selectedSector!].name): \(data[selectedSector!].value)")
                    .font(labelFont)
            }
        }
    }
    
    private func angle(for index: Int) -> Angle {
        let sum = data.reduce(0, { $0 + $1.value })
        return .degrees(data[0..<index].reduce(0, { $0 + $1.value }) / sum * 360.0)
    }
    
    private struct SectorShape: Shape {
        let startAngle: Angle
        let endAngle: Angle
        
        func path(in rect: CGRect) -> Path {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2.0
            var path = Path()
            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.closeSubpath()
            return path
        }
    }
}

struct PieChartViewx_Previews: PreviewProvider {
    
    static var previews: some View {
        PieChartView(data: [
            ("Red", 20),
            ("Green", 30),
            ("Blue", 50)
        ], colors: [
            .red,
            .green,
            .blue
        ], lineWidth: 2, labelFont: .system(size: 14, weight: .bold))
    }
}

