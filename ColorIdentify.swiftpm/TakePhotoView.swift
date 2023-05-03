import SwiftUI
import Charts
import UIKit

struct ColorsArray: Identifiable {
    var id = UUID()
    static var data = [
        ("Red", 20),
        ("Green", 30),
        ("Blue", 50)
    ]
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct RGBColors: Identifiable {
    var id = UUID()
    var color: UIColor
}

var rgbColor = [RGBColors]()

struct TakePhoneView: View {
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var displayImage: Image?
    @State var topColor: [Color] = []
    @State var colors: [ColorData] = []
    @State var colorData: [(String,Double)] = []
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        displayImage = Image(uiImage: inputImage)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let displayImage = displayImage {
                    displayImage
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("Tap to take a photo")
                        .foregroundColor(.gray)
                        .font(.system(size: 24))
                }
                
                Button(action: {
                    guard let img = inputImage else { return print("Failed to calculate the dominant color") }
                    
                    //                    self.topColor = dominantColors(in: img, count: 10)
                    
                    colors = extractColors(from: img, resizedSize: CGSize(width: 8, height: 8))
                    
                    print("Dominant color RGB values: \(topColor)")
                    
                    for i in 0..<colors.count {
                        let str = "R:\(colors[i].red),G:\(colors[i].green),B:\(colors[i].blue)"
                        
                        topColor.append(Color(uiColor: UIColor(red: Double(colors[i].red) / 255, green: Double(colors[i].green) / 255, blue: Double(colors[i].blue) / 255, alpha: 1)))
                        
                        var rgbCount: Double = 0
                        for j in colors {
                            if colors[i].red == j.red && colors[i].green == j.green && colors[i].blue == j.blue {
                                rgbCount += 1
                            }
                        }
                        colorData.append((str,rgbCount))
                    }
                    print("topColor:\(topColor.count)")
                    //                    print("colorData:\(colorData)")
                    print("colorDataCount:\(colorData.count)")
                    
                }, label: {
                    Text("ShowChartButton")
                })
                
                if colorData.count > 0 {
                    let newData = colorData
                    PieChartView(data: newData, colors: topColor, lineWidth: 360/64, labelFont: .system(size: 14, weight: .bold))
                } 
                
            }
            .onTapGesture {
                showingImagePicker = true
                topColor = [Color]()
                colors = [ColorData]()
                colorData = [(String,Double)]()
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
            .navigationBarTitle("Simple Shooter")
        }
        
    }
    
    func dominantColors(in image: UIImage, count: Int = 10) -> [UIColor] {
        let size = CGSize(width: 64, height: 64)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        image.draw(in: CGRect(origin: .zero, size: size))
        
        let bitmapContext = UIGraphicsGetCurrentContext()
        let pixelBuffer = bitmapContext?.data?.assumingMemoryBound(to: UInt8.self)
        
        UIGraphicsEndImageContext()
        
        guard let pixelData = pixelBuffer else {
            return []
        }
        
        var colorCount: [UInt32: Int] = [:]
        
        for x in 0 ..< Int(size.width) {
            for y in 0 ..< Int(size.height) {
                let pixelIndex = ((Int(size.width) * y) + x) * 4
                
                let r = UInt32(pixelData[pixelIndex])
                let g = UInt32(pixelData[pixelIndex + 1])
                let b = UInt32(pixelData[pixelIndex + 2])
                
                let rgb = (r << 16) | (g << 8) | b
                
                if let count = colorCount[rgb] {
                    colorCount[rgb] = count + 1
                } else {
                    colorCount[rgb] = 1
                }
            }
        }
        
        let sortedColorCount = colorCount.sorted { a, b in a.value > b.value }
        let topColors = sortedColorCount.prefix(count)
        
        return topColors.map { entry -> UIColor in
            let rgb = entry.key
            let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgb & 0x0000FF) / 255.0
            
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        }
    }
    
    
}


struct ColorData: Identifiable {
    var id = UUID()
    var red: UInt8
    var green: UInt8
    var blue: UInt8
}

func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let resizedImage = renderer.image { (context) in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
    return resizedImage
}

func extractColors(from image: UIImage, resizedSize: CGSize) -> [ColorData] {
    
    let resizedImage = resizeImage(image: image, targetSize: resizedSize)
    
    guard let pixelData = resizedImage.pixelData else { return [] }
    var colors: [ColorData] = []
    print(pixelData.count)
    for i in stride(from: 0, to: pixelData.count, by: 4) {
        
        let pixelSlice = pixelData[i...i+3]
        let pixel = Array(pixelSlice.prefix(4))
        
        let color = ColorData(red: pixel[0], green: pixel[1], blue: pixel[2])
        colors.append(color)
        
    }
    return colors
}

struct HistogramView: UIViewRepresentable {
    
    var data: [ColorData]
    
    func makeUIView(context: Context) -> Histogram {
        let histogram = Histogram()
        histogram.data = data
        return histogram
    }
    
    func updateUIView(_ uiView: Histogram, context: Context) {
        uiView.data = data
        uiView.setNeedsDisplay()
    }
}

class Histogram: UIView {
    var data: [ColorData] = []
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // 绘制背景
        let bgColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        context.setFillColor(bgColor.cgColor)
        context.fill(rect)
        
        // 统计颜色出现的次数
        var counts: [Int] = Array(repeating: 0, count: 256)
        for color in data {
            counts[Int(color.red)] += 1
            counts[Int(color.green)] += 1
            counts[Int(color.blue)] += 1
        }
        
        // 找到最大的颜色值次数
        let maxCount = counts.max() ?? 0
        
        // 绘制直方图
        let barWidth = rect.width / 256.0
        let barSpacing = barWidth / 2.0
        var x = barSpacing
        for count in counts {
            let barHeight = rect.height * CGFloat(count) / CGFloat(maxCount)
            let barRect = CGRect(x: x, y: rect.height - barHeight, width: barWidth, height: barHeight)
            let barColor = UIColor(red: x / rect.width, green: 0.4, blue: 0.9, alpha: 1.0)
            context.setFillColor(barColor.cgColor)
            context.fill(barRect)
            x += barWidth + barSpacing
        }
    }
}


extension UIImage {
    var pixelData: [UInt8]? {
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 4 * Int(size.width), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return pixelData
    }
}


struct TakePhoneView_Previews: PreviewProvider {
    static var previews: some View {
        TakePhoneView()
    }
}
