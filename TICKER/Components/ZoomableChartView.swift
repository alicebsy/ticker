import SwiftUI
import AppKit

struct ZoomableChartView: View {
    let data: [Double]
    var minVisiblePoints: Int = 10
    
    @State private var zoomLevel: CGFloat = 1.0
    @State private var offset: CGFloat = 0.0
    
    var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }
    
    private var chartColor: Color {
        isPositive ? Color.green : Color.red
    }
    
    // Normalized data with simple moving average for smoothing if needed
    // For now, raw data
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Calculate visible range based on zoom and offset
            // (visibleCount could be used for slicing data when zoomed)
            
            // Clamp offset
            // When zoomed in, we can scroll. the offset is the starting index?
            // Let's implement MagnificationGesture and simple DragGesture for panning
            
            // Simplified approach: Render the whole path but scale and translate it
            // Or better: Slice data to render only visible part for performance?
            // Given data size is likely small, scaling path is easier.
            
            ChartContent(data: data, color: chartColor, width: width, height: height, zoomLevel: zoomLevel)
                .contentShape(Rectangle())
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let tempZoom = max(1.0, min(5.0, value))
                            zoomLevel = tempZoom
                        }
                )
        }
        .clipShape(Rectangle())
    }
}

fileprivate struct ChartContent: View {
    let data: [Double]
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let zoomLevel: CGFloat
    
    var body: some View {
        // Calculate min/max for Y axis scaling
        let minVal = data.min() ?? 0
        let maxVal = data.max() ?? 1
        let range = maxVal - minVal
        
        let stepX = width / CGFloat(max(data.count - 1, 1)) * zoomLevel
        
        // We want to align the RIGHT side of the chart to the right side of the view when zoomed in initially?
        // Or centered?
        // Usually zooming centers on the gesture, but standard "zoom in shows recent" implies anchoring to the right.
        
        // Let's try standard ScrollView implementation for horizontal scrolling of a wide Path
        ScrollView(.horizontal, showsIndicators: false) {
             ZStack {
                 // Gradient Area
                 Path { path in
                     path.move(to: CGPoint(x: 0, y: height))
                     
                     for (index, value) in data.enumerated() {
                         let x = CGFloat(index) * stepX
                         let normalizedValue = (value - minVal) / (range == 0 ? 1 : range)
                         let y = height - (CGFloat(normalizedValue) * height * 0.8) - (height * 0.1) // Padding
                         path.addLine(to: CGPoint(x: x, y: y))
                     }
                     
                     path.addLine(to: CGPoint(x: CGFloat(data.count - 1) * stepX, y: height))
                     path.closeSubpath()
                 }
                 .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                 )
                 
                 // Line
                 Path { path in
                     for (index, value) in data.enumerated() {
                         let x = CGFloat(index) * stepX
                         let normalizedValue = (value - minVal) / (range == 0 ? 1 : range)
                         let y = height - (CGFloat(normalizedValue) * height * 0.8) - (height * 0.1) // Padding
                         
                         if index == 0 {
                             path.move(to: CGPoint(x: x, y: y))
                         } else {
                             path.addLine(to: CGPoint(x: x, y: y))
                         }
                     }
                 }
                 .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                 
                 // Dots on points
                 ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                     let x = CGFloat(index) * stepX
                     let normalizedValue = (value - minVal) / (range == 0 ? 1 : range)
                     let y = height - (CGFloat(normalizedValue) * height * 0.8) - (height * 0.1)
                     
                     Circle()
                         .stroke(color, lineWidth: 2)
                         .background(Circle().fill(Color(nsColor: .windowBackgroundColor)))
                         .frame(width: 8, height: 8)
                         .position(x: x, y: y)
                 }
             }
             .frame(width: CGFloat(data.count) * stepX, height: height)
        }
        .defaultScrollAnchor(.trailing) // Start from the end (most recent)
    }
}
