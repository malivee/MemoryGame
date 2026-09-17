// Penjelasan file: SpeechBubbleNode.swift
// Komponen UI Gelembung Dialog / Text Box (Speech Bubble) reusable.
// Dirancang dengan gaya goresan krayon / pastel lilin (Wax Crayon / Oil Pastel) yang artistik:
// - Warna dasar: Hitam krayon pekat bertekstur (Rich Wax Black #121215)
// - Garis kontur krayon lembut berlapis (chunky rounded wax strokes) dengan variasi tekanan lilin alami
// - Tekstur serat kertas (crayon paper-tooth texture) di sepanjang tepian
// - Garis sketsa krayon kapur putih lembut di bagian dalam (inner chalk highlight)
// - Bentuk tetap sangat rapih, mulus, dan bersih (clean look) dengan keterbacaan teks maksimal

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration

public struct SpeechBubbleConfig {
    public var text: String
    public var fontName: String
    public var fontSize: CGFloat
    public var fontColor: SKColor
    public var backgroundColor: SKColor
    public var crayonStrokeColor: SKColor
    public var padding: CGSize
    public var maxWidth: CGFloat
    public var cornerRadius: CGFloat
    public var showShadow: Bool
    public var showInnerCrayonHighlight: Bool

    public init(
        text: String = "",
        fontName: String = "AvenirNext-Bold",
        fontSize: CGFloat = 21,
        // Teks putih bersih dan tajam
        fontColor: SKColor = .white,
        // Warna Hitam Krayon Lilin (#121215)
        backgroundColor: SKColor = SKColor(red: 0.07, green: 0.07, blue: 0.085, alpha: 0.98),
        // Warna kontur goresan krayon hitam
        crayonStrokeColor: SKColor = SKColor(red: 0.02, green: 0.02, blue: 0.025, alpha: 0.92),
        padding: CGSize = CGSize(width: 36, height: 24),
        maxWidth: CGFloat = 340,
        cornerRadius: CGFloat = 20,
        showShadow: Bool = true,
        showInnerCrayonHighlight: Bool = true
    ) {
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        self.crayonStrokeColor = crayonStrokeColor
        self.padding = padding
        self.maxWidth = maxWidth
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
        self.showInnerCrayonHighlight = showInnerCrayonHighlight
    }
}

// MARK: - Speech Bubble Node

public class SpeechBubbleNode: SKNode {

    private let textLabel = SKLabelNode()
    private var config: SpeechBubbleConfig
    
    // Titik ujung ekor relatif terhadap pusat gelembung
    private var tailTipOffset: CGPoint

    public init(config: SpeechBubbleConfig, tailTipOffset: CGPoint? = nil) {
        self.config = config
        self.tailTipOffset = tailTipOffset ?? CGPoint(x: -80, y: -48)
        super.init()
        
        self.zPosition = 1000
        setupNode()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup & Layout

    private func setupNode() {
        removeAllChildren()
        
        // 1. Setup Label Teks
        setupLabel()
        
        // 2. Hitung dimensi box sesuai isi teks
        let textSize = textLabel.frame.size
        let bubbleWidth = max(textSize.width + (config.padding.width * 2), 125)
        let bubbleHeight = max(textSize.height + (config.padding.height * 2), 68)
        let bubbleSize = CGSize(width: bubbleWidth, height: bubbleHeight)

        let hw = bubbleWidth / 2
        let hh = bubbleHeight / 2

        // Penyesuaian otomatis posisi ekor terhadap ukuran box
        if tailTipOffset.x > -hw {
            tailTipOffset.x = -hw - 12
        }
        if tailTipOffset.y > -hh {
            tailTipOffset.y = -hh - 22
        }

        // 3. Bangun Lapisan Krayon (Crayon Layers) yang Rapih & Bersih
        
        // A. Bayangan Halus di Kertas (Soft Paper Shadow)
        if config.showShadow {
            let shadowPath = createCrayonPath(size: bubbleSize, tailTip: tailTipOffset, seed: 3, variance: 0.5)
            let shadow = SKShapeNode(path: shadowPath)
            shadow.fillColor = SKColor(white: 0.0, alpha: 0.16)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 1.5, y: -4.5)
            shadow.zPosition = 0
            addChild(shadow)
        }

        // B. Body Fill Hitam Lilin (Wax Black Base)
        let fillPath = createCrayonPath(size: bubbleSize, tailTip: tailTipOffset, seed: 15, variance: 0.6)
        let fillNode = SKShapeNode(path: fillPath)
        fillNode.fillColor = config.backgroundColor
        fillNode.strokeColor = config.backgroundColor
        fillNode.lineWidth = 1.0
        fillNode.zPosition = 1
        addChild(fillNode)

        // C. Goresan Krayon Utama (Primary Thick Wax Stroke)
        // Garis tebal berujung membulat lembut khas krayon lilin
        let mainCrayonPath = createCrayonPath(size: bubbleSize, tailTip: tailTipOffset, seed: 28, variance: 1.1)
        let mainCrayonNode = SKShapeNode(path: mainCrayonPath)
        mainCrayonNode.fillColor = .clear
        mainCrayonNode.strokeColor = config.crayonStrokeColor
        mainCrayonNode.lineWidth = 3.4
        mainCrayonNode.lineCap = .round
        mainCrayonNode.lineJoin = .round
        mainCrayonNode.zPosition = 2
        addChild(mainCrayonNode)

        // D. Tekstur Goresan Krayon Sekunder (Secondary Crayon Grain)
        // Meniru goresan krayon kedua yang agak lepas mengenai serat kertas
        let grainPath = createCrayonPath(size: bubbleSize, tailTip: tailTipOffset, seed: 47, variance: 1.8)
        let grainNode = SKShapeNode(path: grainPath)
        grainNode.fillColor = .clear
        grainNode.strokeColor = config.crayonStrokeColor.withAlphaComponent(0.48)
        grainNode.lineWidth = 1.8
        grainNode.lineCap = .round
        grainNode.lineJoin = .round
        grainNode.zPosition = 3
        addChild(grainNode)

        // E. Aksen Goresan Lilin di Sudut & Ekor (Crayon Wax Accents)
        let waxAccents = createCrayonWaxAccents(size: bubbleSize, tailTip: tailTipOffset)
        let accentsNode = SKShapeNode(path: waxAccents)
        accentsNode.fillColor = .clear
        accentsNode.strokeColor = config.crayonStrokeColor.withAlphaComponent(0.60)
        accentsNode.lineWidth = 2.2
        accentsNode.lineCap = .round
        accentsNode.zPosition = 4
        addChild(accentsNode)

        // F. Garis Krayon Kapur Putih di Dalam (Inner Chalk Crayon Highlight)
        // Garis krayon putih tipis yang ditarik lembut di dalam tepi kotak hitam
        if config.showInnerCrayonHighlight {
            let innerSize = CGSize(width: bubbleSize.width - 10, height: bubbleHeight - 10)
            let innerTailTip = CGPoint(x: tailTipOffset.x + 4.0, y: tailTipOffset.y + 4.5)
            let innerPath = createCrayonPath(size: innerSize, tailTip: innerTailTip, seed: 92, variance: 0.9)
            let innerNode = SKShapeNode(path: innerPath)
            innerNode.fillColor = .clear
            innerNode.strokeColor = SKColor(white: 1.0, alpha: 0.22)
            innerNode.lineWidth = 1.5
            innerNode.lineCap = .round
            innerNode.lineJoin = .round
            innerNode.zPosition = 5
            addChild(innerNode)
        }

        // G. Teks di Lapisan Teratas (Sangat Bersih & Tajam)
        textLabel.zPosition = 10
        addChild(textLabel)
    }

    private func setupLabel() {
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = config.maxWidth
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center

        #if canImport(UIKit)
        let targetSize = config.fontSize
        let descriptor: UIFontDescriptor
        if let rounded = UIFont.systemFont(ofSize: targetSize, weight: .bold).fontDescriptor.withDesign(.rounded) {
            descriptor = rounded
        } else {
            descriptor = UIFont.boldSystemFont(ofSize: targetSize).fontDescriptor
        }
        let font = UIFont(descriptor: descriptor, size: targetSize)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 3.0

        let attr: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: config.fontColor,
            .paragraphStyle: paragraph
        ]
        textLabel.attributedText = NSAttributedString(string: config.text, attributes: attr)
        #else
        textLabel.text = config.text
        textLabel.fontName = config.fontName
        textLabel.fontSize = config.fontSize
        textLabel.fontColor = config.fontColor
        #endif
    }

    // MARK: - Dynamic Updates

    public func setText(_ newText: String) {
        config.text = newText
        setupNode()
    }

    // MARK: - Crayon Path Generator

    /// Menghasilkan kurva krayon lilin yang lembut, tebal, dan bernuansa goresan tangan alami.
    private func createCrayonPath(
        size: CGSize,
        tailTip: CGPoint,
        seed: Int,
        variance: CGFloat = 0.0
    ) -> CGPath {
        let hw = size.width / 2
        let hh = size.height / 2
        let cr = min(config.cornerRadius, min(hw, hh) * 0.45)

        func j(_ index: Int, _ mult: CGFloat) -> CGFloat {
            guard variance > 0 else { return 0 }
            var x = UInt32(truncatingIfNeeded: ((seed + index) &* 1103515245) &+ 12345)
            x = (x ^ (x >> 13)) &* 1274126177
            let val = CGFloat(x & 0x00FFFFFF) / CGFloat(0x00FFFFFF)
            return (val - 0.5) * 2.0 * variance * mult
        }

        let path = CGMutablePath()

        // Titik-titik sudut & lengkungan membulat khas krayon
        let topStart = CGPoint(x: -hw + cr + j(1, 0.5), y: hh + j(2, 0.6))
        let topEnd   = CGPoint(x:  hw - cr + j(3, 0.5), y: hh + j(4, 0.6))
        let topCtrl  = CGPoint(x: 0 + j(5, 0.9), y: hh + 2.5 + j(6, 0.8))

        let rightStart = CGPoint(x: hw + j(7, 0.6), y:  hh - cr + j(8, 0.5))
        let rightEnd   = CGPoint(x: hw + j(9, 0.6), y: -hh + cr + j(10, 0.5))
        let rightCtrl  = CGPoint(x: hw + 2.5 + j(11, 0.8), y: 0 + j(12, 0.9))

        let tailBaseBottom = CGPoint(x: -hw + 40.0 + j(13, 0.7), y: -hh + j(14, 0.6))
        let bottomStart    = CGPoint(x:  hw - cr + j(15, 0.5), y: -hh + j(16, 0.6))
        let bottomCtrl     = CGPoint(x: 0 + j(17, 0.9), y: -hh - 2.5 + j(18, 0.8))

        let tip = CGPoint(x: tailTip.x + j(19, 0.7), y: tailTip.y + j(20, 0.7))
        let tailBaseLeft = CGPoint(x: -hw + j(21, 0.6), y: -hh + 25.0 + j(22, 0.7))

        let leftStart = CGPoint(x: -hw + j(23, 0.6), y: -hh + 25.0 + j(24, 0.5))
        let leftEnd   = CGPoint(x: -hw + j(25, 0.6), y:  hh - cr + j(26, 0.5))
        let leftCtrl  = CGPoint(x: -hw - 2.5 + j(27, 0.8), y: 0 + j(28, 0.9))

        // 1. Sisi Atas (Lengkungan krayon lembut)
        path.move(to: topStart)
        path.addQuadCurve(to: topEnd, control: topCtrl)

        // 2. Sudut Kanan-Atas (Membulat tumpul khas ujung krayon)
        path.addQuadCurve(to: rightStart, control: CGPoint(x: hw + j(29, 0.5), y: hh + j(30, 0.5)))

        // 3. Sisi Kanan
        path.addQuadCurve(to: rightEnd, control: rightCtrl)

        // 4. Sudut Kanan-Bawah
        path.addQuadCurve(to: bottomStart, control: CGPoint(x: hw + j(31, 0.5), y: -hh + j(32, 0.5)))

        // 5. Sisi Bawah
        path.addQuadCurve(to: tailBaseBottom, control: bottomCtrl)

        // 6. Ekor Krayon Menukik ke Ujung Tip
        let tailDownCtrl = CGPoint(x: -hw + 15.0 + j(33, 0.9), y: -hh - 8.0 + j(34, 0.9))
        path.addQuadCurve(to: tip, control: tailDownCtrl)

        // 7. Ekor Krayon Naik ke Kiri
        let tailUpCtrl = CGPoint(x: tip.x + 19.0 + j(35, 0.9), y: tip.y + 16.0 + j(36, 0.9))
        path.addQuadCurve(to: tailBaseLeft, control: tailUpCtrl)

        // 8. Sisi Kiri
        path.move(to: leftStart)
        path.addQuadCurve(to: leftEnd, control: leftCtrl)

        // 9. Sudut Kiri-Atas (Menutup dengan mulus)
        path.addQuadCurve(to: topStart, control: CGPoint(x: -hw + j(37, 0.5), y: hh + j(38, 0.5)))

        path.closeSubpath()
        return path
    }

    /// Goresan krayon aksen di sudut-sudut dan ekor (meniru penumpukan lilin krayon alami)
    private func createCrayonWaxAccents(size: CGSize, tailTip: CGPoint) -> CGPath {
        let hw = size.width / 2
        let hh = size.height / 2
        let path = CGMutablePath()

        // 1. Sudut Kiri-Atas: goresan krayon berulang pendek
        path.move(to: CGPoint(x: -hw - 3.5, y: hh - 8.0))
        path.addQuadCurve(to: CGPoint(x: -hw + 14.0, y: hh + 2.5), control: CGPoint(x: -hw - 1.0, y: hh + 2.0))

        // 2. Sudut Kanan-Atas: goresan krayon melengkung
        path.move(to: CGPoint(x: hw - 14.0, y: hh + 2.0))
        path.addQuadCurve(to: CGPoint(x: hw + 3.0, y: hh - 8.0), control: CGPoint(x: hw + 1.5, y: hh + 1.5))

        // 3. Sudut Kanan-Bawah
        path.move(to: CGPoint(x: hw - 12.0, y: -hh - 1.5))
        path.addQuadCurve(to: CGPoint(x: hw + 2.5, y: -hh + 8.0), control: CGPoint(x: hw + 1.0, y: -hh - 1.0))

        // 4. Aksen sapuan lilin pada ekor
        path.move(to: CGPoint(x: tailTip.x - 3.0, y: tailTip.y - 2.5))
        path.addLine(to: CGPoint(x: tailTip.x + 10.0, y: tailTip.y + 8.0))

        return path
    }

    // MARK: - Animations

    public func popIn() {
        self.setScale(0.1)
        self.alpha = 0.0
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let scaleUp = SKAction.scale(to: 1.04, duration: 0.14)
        let bounce = SKAction.scale(to: 1.0, duration: 0.10)
        
        scaleUp.timingMode = .easeOut
        bounce.timingMode = .easeInEaseOut
        
        self.run(.group([fadeIn, .sequence([scaleUp, bounce])]))
    }

    public func popOut(completion: (() -> Void)? = nil) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.14)
        let scaleDown = SKAction.scale(to: 0.88, duration: 0.14)
        scaleDown.timingMode = .easeIn
        self.run(.group([fadeOut, scaleDown])) { [weak self] in
            completion?()
            self?.removeFromParent()
        }
    }
}

// MARK: - SwiftUI Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview("Clean Black Crayon Textbox") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 480, height: 260))
        scene.scaleMode = .resizeFill
        // Canvas netral terang yang bersih murni (clean sketchbook paper),
        // membuat tekstur krayon hitam terlihat sangat menawan dan jelas.
        scene.backgroundColor = SKColor(red: 0.94, green: 0.94, blue: 0.93, alpha: 1.0)
        
        // Setup Textbox Krayon Hitam Murni
        let config = SpeechBubbleConfig(
            text: "Hmm, and there's a strange",
            fontSize: 21,
            padding: CGSize(width: 36, height: 24)
        )
        
        // Ekor runcing krayon di sudut kiri-bawah
        let bubble = SpeechBubbleNode(config: config, tailTipOffset: CGPoint(x: -125, y: -48))
        bubble.position = CGPoint(x: 250, y: 130)
        scene.addChild(bubble)
        
        bubble.popIn()
        
        return scene
    }())
    .frame(width: 480, height: 260)
    .ignoresSafeArea()
}
#endif



