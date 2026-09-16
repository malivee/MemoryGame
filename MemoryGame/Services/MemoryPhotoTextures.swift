import SpriteKit
import UIKit

final class MemoryPhotoTextures {
    private let photo = UIImage(named: "final photo")!
    private var cache: [MemoryPiece: SKTexture] = [:]

    func texture(_ piece: MemoryPiece) -> SKTexture {
        if let cached = cache[piece] { return cached }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let side: CGFloat = 360
        let cell = CGSize(width: photo.size.width / 3, height: photo.size.height / 3)
        let output = CGSize(width: side, height: side * cell.height / cell.width)
        let image = UIGraphicsImageRenderer(size: output, format: format).image { context in
            photo.draw(in: CGRect(x: -CGFloat(piece.slot % 3) * output.width,
                                  y: -CGFloat(piece.slot / 3) * output.height,
                                  width: output.width * 3, height: output.height * 3))
            if piece == .dryLake {
                // Same photographic location and outline; an ordinary local variant.
                let basin = UIBezierPath()
                basin.move(to: CGPoint(x: 0, y: output.height * 0.05))
                basin.addCurve(to: CGPoint(x: output.width * 0.98, y: output.height * 0.23),
                               controlPoint1: CGPoint(x: output.width * 0.44, y: -18),
                               controlPoint2: CGPoint(x: output.width * 0.78, y: 10))
                basin.addCurve(to: CGPoint(x: 0, y: output.height * 0.92),
                               controlPoint1: CGPoint(x: output.width * 0.95, y: output.height * 0.63),
                               controlPoint2: CGPoint(x: output.width * 0.3, y: output.height * 0.96))
                basin.close()
                UIColor(red: 0.57, green: 0.44, blue: 0.27, alpha: 0.92).setFill()
                basin.fill()
                context.cgContext.saveGState()
                basin.addClip()
                UIColor(red: 0.32, green: 0.25, blue: 0.17, alpha: 0.5).setStroke()
                for index in 0..<8 {
                    let crack = UIBezierPath()
                    let x = CGFloat(index) * 52
                    crack.move(to: CGPoint(x: x, y: 25))
                    crack.addLine(to: CGPoint(x: x + 14, y: 90))
                    crack.addLine(to: CGPoint(x: x - 6, y: 140))
                    crack.lineWidth = 1.5
                    crack.stroke()
                }
                context.cgContext.restoreGState()
            }
        }
        let texture = SKTexture(image: image)
        cache[piece] = texture
        return texture
    }
}
