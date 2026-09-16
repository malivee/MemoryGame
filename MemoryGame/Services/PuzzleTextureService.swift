//
//  PuzzleTextureService.swift
//  MemoryGame
//

import SpriteKit
import UIKit

/// Cuts all 48 interlocking pieces from the same photo used for the final reveal.
final class PuzzleTextureService {
    private let photo: UIImage
    private var textures: [String: SKTexture] = [:]

    init() {
        guard let photo = UIImage(named: PuzzleCatalog.imageName) else {
            preconditionFailure("Missing puzzle photo: \(PuzzleCatalog.imageName)")
        }
        self.photo = photo
    }

    func texture(for piece: PuzzlePieceData, dryVariant: Bool = false) -> SKTexture {
        let key = piece.id + (dryVariant ? "-dry" : "")
        if let texture = textures[key] { return texture }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: ceil(piece.width), height: ceil(piece.height)),
            format: format
        )
        let image = renderer.image { context in
            // Fractional row sizes must still fill the sprite's exact logical bounds.
            context.cgContext.scaleBy(
                x: ceil(piece.width) / piece.width,
                y: ceil(piece.height) / piece.height
            )
            let path = UIBezierPath(cgPath: JigsawOutline.path(for: piece))
            context.cgContext.saveGState()
            path.addClip()
            photo.draw(in: CGRect(
                x: -piece.targetX, y: -piece.targetY,
                width: PuzzleCatalog.canvasWidth, height: PuzzleCatalog.canvasHeight
            ))
            if dryVariant {
                context.cgContext.setBlendMode(.color)
                UIColor(red: 0.62, green: 0.45, blue: 0.25, alpha: 1).setFill()
                context.cgContext.fill(CGRect(x: 0, y: 0, width: piece.width, height: piece.height))
                context.cgContext.setBlendMode(.normal)
                UIColor(red: 0.43, green: 0.31, blue: 0.18, alpha: 0.65).setStroke()
                for index in 0..<7 {
                    let crack = UIBezierPath()
                    let x = CGFloat(index) * piece.width / 7
                    crack.move(to: CGPoint(x: x, y: 35))
                    crack.addLine(to: CGPoint(x: x + 13, y: piece.height * 0.5))
                    crack.addLine(to: CGPoint(x: x - 4, y: piece.height - 24))
                    crack.lineWidth = 1.5
                    crack.stroke()
                }
            }
            context.cgContext.restoreGState()
            UIColor.black.withAlphaComponent(0.18).setStroke()
            path.lineWidth = 0.8
            path.stroke()
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        textures[key] = texture
        return texture
    }

}
