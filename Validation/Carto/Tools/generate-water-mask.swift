import Foundation
import CoreGraphics
import ImageIO
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
let width = image.width, height = image.height
var pixels = [UInt8](repeating: 0, count: width * height * 4)
let blocked: Set<Int> = pixels.withUnsafeMutableBytes { bytes in
    let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                            bitsPerComponent: 8, bytesPerRow: width*4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.draw(image, in: CGRect(x:0,y:0,width:width,height:height))
    let data = bytes.bindMemory(to: UInt8.self)
    var cells: Set<Int> = []
    for y in 0..<height {
        for x in 0..<width {
            let i = (y*width+x)*4
            let r = Int(data[i]), g = Int(data[i+1]), b = Int(data[i+2])
            if g > r+20 && b > r+35 && b >= g-10 {
                let column = x*54/width
                let row = 29-y*30/height
                cells.insert(row*54+column)
            }
        }
    }
    return cells
}
print(blocked.sorted().map(String.init).joined(separator:", "))
