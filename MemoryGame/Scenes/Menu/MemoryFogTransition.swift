import SpriteKit
import UIKit

/// A view-level veil remains continuous while SpriteKit swaps the scene beneath it.
enum MemoryFogTransition {
    static func present(_ destination: SKScene, from source: SKScene, in view: SKView) {
        let overlay = UIView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isUserInteractionEnabled = true
        overlay.accessibilityViewIsModal = true
        let veil = UIView(frame: overlay.bounds)
        veil.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        veil.backgroundColor = UIColor(red: 0.77, green: 0.81, blue: 0.77, alpha: 1)
        veil.alpha = 0
        overlay.addSubview(veil)

        let reducedMotion = UIAccessibility.isReduceMotionEnabled
        let texture = cloudTexture()
        var clouds: [UIImageView] = []
        for index in 0..<12 {
            let cloud = UIImageView(image: texture)
            let diameter = max(view.bounds.width, view.bounds.height) * 0.8
            cloud.bounds.size = CGSize(width: diameter, height: diameter * 0.65)
            let column = CGFloat(index % 4) / 3
            let row = CGFloat(index / 4) / 2
            cloud.center = CGPoint(x: view.bounds.width * column, y: view.bounds.height * row)
            cloud.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            cloud.alpha = 0
            overlay.addSubview(cloud)
            clouds.append(cloud)
        }
        view.addSubview(overlay)
        for (index, cloud) in clouds.enumerated() {
            UIView.animate(withDuration: reducedMotion ? 0.25 : 1.25,
                           delay: reducedMotion ? 0 : Double(index % 4) * 0.06,
                           options: [.curveEaseInOut]) {
                cloud.alpha = 0.85
                if !reducedMotion {
                    cloud.transform = CGAffineTransform(translationX: index.isMultiple(of: 2) ? 45 : -45, y: -20)
                        .scaledBy(x: 1.35, y: 1.35)
                }
            }
        }
        // Full coverage hides the scene swap; clouds then drift away over the puzzle.
        UIView.animate(withDuration: reducedMotion ? 0.3 : 1.5, delay: 0, options: [.curveEaseIn]) {
            veil.alpha = 1
        } completion: { [weak view, weak source] _ in
            guard let view, let source, view.scene === source else {
                overlay.removeFromSuperview()
                return
            }
            destination.size = view.bounds.size
            view.presentScene(destination)
            UIView.animate(withDuration: reducedMotion ? 0.3 : 1.6, delay: 0.1, options: [.curveEaseOut]) {
                veil.alpha = 0
                for (index, cloud) in clouds.enumerated() {
                    cloud.alpha = 0
                    if !reducedMotion {
                        cloud.transform = CGAffineTransform(translationX: index.isMultiple(of: 2) ? 130 : -130, y: -65)
                            .scaledBy(x: 1.8, y: 1.8)
                    }
                }
            } completion: { _ in overlay.removeFromSuperview() }
        }
    }

    private static func cloudTexture() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { renderer in
            let colors = [UIColor(red: 0.89, green: 0.91, blue: 0.85, alpha: 0.95).cgColor,
                          UIColor(red: 0.80, green: 0.85, blue: 0.80, alpha: 0.45).cgColor,
                          UIColor(red: 0.80, green: 0.85, blue: 0.80, alpha: 0).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray,
                                      locations: [0, 0.45, 1])!
            renderer.cgContext.drawRadialGradient(gradient, startCenter: CGPoint(x: 128, y: 128), startRadius: 0,
                                                  endCenter: CGPoint(x: 128, y: 128), endRadius: 128, options: [])
        }
    }
}
