// Penjelasan file: SpeechBubbleNode.swift
// Komponen UI Gelembung Dialog / Text Box (Speech Bubble) reusable.
// Dirancang dengan gaya goresan krayon / pastel lilin (Wax Crayon / Oil Pastel) artistik:
// - Mendukung nama pembicara (speaker name) beraksen emas hangat
// - Mendukung teks dialog multiline bersih dan tajam
// - Mendukung indikator halaman/petunjuk (page indicator) di bagian bawah
// - Ekor krayon dinamis yang dapat menunjuk ke karakter pembicara dari berbagai sudut
// - Warna dasar: Hitam krayon pekat bertekstur (Rich Wax Black #121215)
// - Garis kontur krayon tebal bertekstur lilin dan serat kertas
// - Garis highlight krayon kapur putih lembut di bagian dalam

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration

public struct SpeechBubbleConfig {
    public var text: String
    public var speaker: String?
    public var pageIndicator: String?
    public var fontName: String
    public var fontSize: CGFloat
    public var fontColor: SKColor
    public var speakerColor: SKColor
    public var backgroundColor: SKColor
    public var crayonStrokeColor: SKColor
    public var padding: CGSize
    public var maxWidth: CGFloat
    public var cornerRadius: CGFloat
    public var showShadow: Bool
    public var showInnerCrayonHighlight: Bool

    public init(
        text: String = "",
        speaker: String? = nil,
        pageIndicator: String? = nil,
        fontName: String = "AvenirNext-Bold",
        fontSize: CGFloat = 19,
        // Teks putih bersih dan tajam
        fontColor: SKColor = .white,
        // Warna emas hangat untuk nama pembicara (#F6D57A)
        speakerColor: SKColor = SKColor(red: 0.96, green: 0.83, blue: 0.48, alpha: 1.0),
        // Warna Hitam Krayon Lilin (#121215)
        backgroundColor: SKColor = SKColor(red: 0.07, green: 0.07, blue: 0.085, alpha: 0.98),
        // Warna kontur goresan krayon hitam
        crayonStrokeColor: SKColor = SKColor(red: 0.02, green: 0.02, blue: 0.025, alpha: 0.92),
        padding: CGSize = CGSize(width: 30, height: 18),
        maxWidth: CGFloat = 380,
        cornerRadius: CGFloat = 18,
        showShadow: Bool = true,
        showInnerCrayonHighlight: Bool = true
    ) {
        self.text = text
        self.speaker = speaker
        self.pageIndicator = pageIndicator
        self.fontName = fontName
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.speakerColor = speakerColor
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

    private var config: SpeechBubbleConfig
    
    // Titik ujung ekor relatif terhadap pusat gelembung
    private var tailTipOffset: CGPoint

    public init(config: SpeechBubbleConfig, tailTipOffset: CGPoint? = nil) {
        self.config = config
        self.tailTipOffset = tailTipOffset ?? CGPoint(x: -60, y: -45)
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
        
        // 1. Siapkan Node Konten (Speaker, Teks, Indicator)
        var speakerLabel: SKLabelNode?
        var indicatorLabel: SKLabelNode?
        let textLabel = SKLabelNode()

        // Setup Speaker Name jika ada
        if let speaker = config.speaker, !speaker.isEmpty {
            let sLabel = SKLabelNode()
            sLabel.horizontalAlignmentMode = .center
            sLabel.verticalAlignmentMode = .center
            #if canImport(UIKit)
            let sFont = UIFont.systemFont(ofSize: 15, weight: .heavy)
            sLabel.attributedText = NSAttributedString(string: speaker.uppercased(), attributes: [
                .font: sFont,
                .foregroundColor: config.speakerColor,
                .kern: 1.2
            ])
            #else
            sLabel.text = speaker.uppercased()
            sLabel.fontSize = 15
            sLabel.fontColor = config.speakerColor
            #endif
            speakerLabel = sLabel
        }

        // Setup Text Label
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = config.maxWidth
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center
        #if canImport(UIKit)
        let targetSize = config.fontSize
        let descriptor = UIFont.systemFont(ofSize: targetSize, weight: .bold).fontDescriptor.withDesign(.rounded) ?? UIFont.boldSystemFont(ofSize: targetSize).fontDescriptor
        let font = UIFont(descriptor: descriptor, size: targetSize)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 3.0
        textLabel.attributedText = NSAttributedString(string: config.text, attributes: [
            .font: font,
            .foregroundColor: config.fontColor,
            .paragraphStyle: paragraph
        ])
        #else
        textLabel.text = config.text
        textLabel.fontName = config.fontName
        textLabel.fontSize = config.fontSize
        textLabel.fontColor = config.fontColor
        #endif

        // Setup Page Indicator jika ada
        if let indicator = config.pageIndicator, !indicator.isEmpty {
            let iLabel = SKLabelNode()
            iLabel.horizontalAlignmentMode = .center
            iLabel.verticalAlignmentMode = .center
            #if canImport(UIKit)
            let iFont = UIFont.systemFont(ofSize: 11, weight: .medium)
            iLabel.attributedText = NSAttributedString(string: indicator, attributes: [
                .font: iFont,
                .foregroundColor: SKColor(white: 0.65, alpha: 1.0)
            ])
            #else
            iLabel.text = indicator
            iLabel.fontSize = 11
            iLabel.fontColor = SKColor(white: 0.65, alpha: 1.0)
            #endif
            indicatorLabel = iLabel
        }

        // 2. Hitung Dimensi Gelembung
        let speakerH: CGFloat = speakerLabel != nil ? 20 : 0
        let indicatorH: CGFloat = indicatorLabel != nil ? 16 : 0
        let textH: CGFloat = textLabel.frame.size.height
        let textW: CGFloat = textLabel.frame.size.width
        let speakerW: CGFloat = speakerLabel?.frame.size.width ?? 0

        let contentW = max(textW, speakerW)
        let bubbleWidth = max(contentW + (config.padding.width * 2), 140)
        
        let spacingTop: CGFloat = speakerH > 0 ? 6 : 0
        let spacingBottom: CGFloat = indicatorH > 0 ? 6 : 0
        let contentH = speakerH + spacingTop + textH + spacingBottom + indicatorH
        let bubbleHeight = max(contentH + (config.padding.height * 2), 64)

        let bubbleSize = CGSize(width: bubbleWidth, height: bubbleHeight)
        let hw = bubbleWidth / 2
        let hh = bubbleHeight / 2

        // Penyesuaian batas offset ekor
        if tailTipOffset.y <= 0 && tailTipOffset.y > -hh - 12 {
            tailTipOffset.y = -hh - 18
        } else if tailTipOffset.y > 0 && tailTipOffset.y < hh + 12 {
            tailTipOffset.y = hh + 18
        }
        tailTipOffset.x = min(max(tailTipOffset.x, -hw - 20), hw + 20)

        // 3. Bangun Lapisan Krayon
        
        // A. Bayangan Halus
        if config.showShadow {
            let shadowPath = createCrayonPath(size: bubbleSize, tailTip: tailTipOffset, seed: 3, variance: 0.5)
            let shadow = SKShapeNode(path: shadowPath)
            shadow.fillColor = SKColor(white: 0.0, alpha: 0.16)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 1.5, y: -4.0)
            shadow.zPosition = 0
            addChild(shadow)
        }

        // B. Body Fill Hitam Krayon
        let fillPath = createCrayonPath(size: bubbleSize, tailTip: tailTipOffset, seed: 15, variance: 0.6)
        let fillNode = SKShapeNode(path: fillPath)
        fillNode.fillColor = config.backgroundColor
        fillNode.strokeColor = config.backgroundColor
        fillNode.lineWidth = 1.0
        fillNode.zPosition = 1
        addChild(fillNode)

        // C. Goresan Krayon Utama
        let mainCrayonPath = createCrayonPath(size: bubbleSize, tailTip: tailTipOffset, seed: 28, variance: 1.1)
        let mainCrayonNode = SKShapeNode(path: mainCrayonPath)
        mainCrayonNode.fillColor = .clear
        mainCrayonNode.strokeColor = config.crayonStrokeColor
        mainCrayonNode.lineWidth = 3.2
        mainCrayonNode.lineCap = .round
        mainCrayonNode.lineJoin = .round
        mainCrayonNode.zPosition = 2
        addChild(mainCrayonNode)

        // D. Tekstur Goresan Krayon Sekunder
        let grainPath = createCrayonPath(size: bubbleSize, tailTip: tailTipOffset, seed: 47, variance: 1.6)
        let grainNode = SKShapeNode(path: grainPath)
        grainNode.fillColor = .clear
        grainNode.strokeColor = config.crayonStrokeColor.withAlphaComponent(0.45)
        grainNode.lineWidth = 1.6
        grainNode.lineCap = .round
        grainNode.lineJoin = .round
        grainNode.zPosition = 3
        addChild(grainNode)

        // E. Aksen Goresan Lilin di Sudut
        let waxAccents = createCrayonWaxAccents(size: bubbleSize, tailTip: tailTipOffset)
        let accentsNode = SKShapeNode(path: waxAccents)
        accentsNode.fillColor = .clear
        accentsNode.strokeColor = config.crayonStrokeColor.withAlphaComponent(0.60)
        accentsNode.lineWidth = 2.0
        accentsNode.lineCap = .round
        accentsNode.zPosition = 4
        addChild(accentsNode)

        // F. Garis Krayon Kapur Putih di Dalam
        if config.showInnerCrayonHighlight {
            let innerSize = CGSize(width: bubbleSize.width - 10, height: bubbleHeight - 10)
            let innerTailTip = CGPoint(
                x: tailTipOffset.x * 0.88,
                y: tailTipOffset.y > 0 ? tailTipOffset.y - 4.0 : tailTipOffset.y + 4.0
            )
            let innerPath = createCrayonPath(size: innerSize, tailTip: innerTailTip, seed: 92, variance: 0.8)
            let innerNode = SKShapeNode(path: innerPath)
            innerNode.fillColor = .clear
            innerNode.strokeColor = SKColor(white: 1.0, alpha: 0.20)
            innerNode.lineWidth = 1.3
            innerNode.lineCap = .round
            innerNode.lineJoin = .round
            innerNode.zPosition = 5
            addChild(innerNode)
        }

        // 4. Posisikan Konten Teks di Lapisan Teratas
        let topY = hh - config.padding.height
        var currentY = topY

        if let sLabel = speakerLabel {
            currentY -= speakerH / 2
            sLabel.position = CGPoint(x: 0, y: currentY)
            sLabel.zPosition = 10
            addChild(sLabel)
            currentY -= (speakerH / 2 + spacingTop)
        }

        currentY -= textH / 2
        textLabel.position = CGPoint(x: 0, y: currentY)
        textLabel.zPosition = 10
        addChild(textLabel)
        currentY -= (textH / 2 + spacingBottom)

        if let iLabel = indicatorLabel {
            currentY -= indicatorH / 2
            iLabel.position = CGPoint(x: 0, y: currentY)
            iLabel.zPosition = 10
            addChild(iLabel)
        }
    }

    // MARK: - Dynamic Updates

    public func setText(_ newText: String, speaker: String? = nil, pageIndicator: String? = nil) {
        config.text = newText
        if let s = speaker { config.speaker = s }
        if let p = pageIndicator { config.pageIndicator = p }
        setupNode()
    }

    public func updateTail(offset: CGPoint) {
        self.tailTipOffset = offset
        setupNode()
    }

    // MARK: - Crayon Path Generator

    /// Menghasilkan kurva krayon lilin fleksibel dengan posisi ekor dinamis
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
        let tailPointsDown = tailTip.y <= 0
        let baseCenterX = min(max(tailTip.x, -hw + 35), hw - 35)

        // Titik-titik sudut dasar
        let topStart = CGPoint(x: -hw + cr + j(1, 0.5), y: hh + j(2, 0.6))
        let topEnd   = CGPoint(x:  hw - cr + j(3, 0.5), y: hh + j(4, 0.6))
        let topCtrl  = CGPoint(x: 0 + j(5, 0.9), y: hh + 2.2 + j(6, 0.8))

        let rightStart = CGPoint(x: hw + j(7, 0.6), y:  hh - cr + j(8, 0.5))
        let rightEnd   = CGPoint(x: hw + j(9, 0.6), y: -hh + cr + j(10, 0.5))
        let rightCtrl  = CGPoint(x: hw + 2.2 + j(11, 0.8), y: 0 + j(12, 0.9))

        let bottomStart = CGPoint(x:  hw - cr + j(15, 0.5), y: -hh + j(16, 0.6))
        let bottomEnd   = CGPoint(x: -hw + cr + j(17, 0.5), y: -hh + j(18, 0.6))

        let leftStart = CGPoint(x: -hw + j(23, 0.6), y: -hh + cr + j(24, 0.5))
        let leftEnd   = CGPoint(x: -hw + j(25, 0.6), y:  hh - cr + j(26, 0.5))
        let leftCtrl  = CGPoint(x: -hw - 2.2 + j(27, 0.8), y: 0 + j(28, 0.9))

        // 1. Sisi Atas
        path.move(to: topStart)
        if !tailPointsDown {
            // Ekor menunjuk ke atas
            let tBase1 = CGPoint(x: baseCenterX - 15 + j(31, 0.6), y: hh + j(32, 0.5))
            let tBase2 = CGPoint(x: baseCenterX + 15 + j(33, 0.6), y: hh + j(34, 0.5))
            path.addLine(to: tBase1)
            path.addQuadCurve(to: tailTip, control: CGPoint(x: (tBase1.x + tailTip.x) / 2 - 4, y: (hh + tailTip.y) / 2))
            path.addQuadCurve(to: tBase2, control: CGPoint(x: (tBase2.x + tailTip.x) / 2 + 4, y: (hh + tailTip.y) / 2))
            path.addLine(to: topEnd)
        } else {
            path.addQuadCurve(to: topEnd, control: topCtrl)
        }

        // 2. Sudut Kanan-Atas
        path.addQuadCurve(to: rightStart, control: CGPoint(x: hw + j(29, 0.5), y: hh + j(30, 0.5)))

        // 3. Sisi Kanan
        path.addQuadCurve(to: rightEnd, control: rightCtrl)

        // 4. Sudut Kanan-Bawah
        path.addQuadCurve(to: bottomStart, control: CGPoint(x: hw + j(31, 0.5), y: -hh + j(32, 0.5)))

        // 5. Sisi Bawah
        if tailPointsDown {
            // Ekor menunjuk ke bawah
            let tBase1 = CGPoint(x: baseCenterX + 16 + j(35, 0.6), y: -hh + j(36, 0.5))
            let tBase2 = CGPoint(x: baseCenterX - 16 + j(37, 0.6), y: -hh + j(38, 0.5))
            path.addLine(to: tBase1)
            let downCtrl1 = CGPoint(x: (tBase1.x + tailTip.x) / 2 + 4, y: (-hh + tailTip.y) / 2)
            path.addQuadCurve(to: tailTip, control: downCtrl1)
            let downCtrl2 = CGPoint(x: (tBase2.x + tailTip.x) / 2 - 4, y: (-hh + tailTip.y) / 2)
            path.addQuadCurve(to: tBase2, control: downCtrl2)
            path.addLine(to: bottomEnd)
        } else {
            path.addQuadCurve(to: bottomEnd, control: CGPoint(x: 0 + j(17, 0.9), y: -hh - 2.2 + j(18, 0.8)))
        }

        // 6. Sudut Kiri-Bawah
        path.addQuadCurve(to: leftStart, control: CGPoint(x: -hw + j(39, 0.5), y: -hh + j(40, 0.5)))

        // 7. Sisi Kiri
        path.addQuadCurve(to: leftEnd, control: leftCtrl)

        // 8. Sudut Kiri-Atas
        path.addQuadCurve(to: topStart, control: CGPoint(x: -hw + j(41, 0.5), y: hh + j(42, 0.5)))

        path.closeSubpath()
        return path
    }

    /// Aksen goresan krayon di sudut dan ekor
    private func createCrayonWaxAccents(size: CGSize, tailTip: CGPoint) -> CGPath {
        let hw = size.width / 2
        let hh = size.height / 2
        let path = CGMutablePath()

        // Sudut Kiri-Atas
        path.move(to: CGPoint(x: -hw - 3.0, y: hh - 8.0))
        path.addQuadCurve(to: CGPoint(x: -hw + 12.0, y: hh + 2.0), control: CGPoint(x: -hw - 0.5, y: hh + 1.5))

        // Sudut Kanan-Atas
        path.move(to: CGPoint(x: hw - 12.0, y: hh + 2.0))
        path.addQuadCurve(to: CGPoint(x: hw + 2.5, y: hh - 8.0), control: CGPoint(x: hw + 1.0, y: hh + 1.0))

        // Ujung Ekor
        let signY: CGFloat = tailTip.y <= 0 ? 1 : -1
        path.move(to: CGPoint(x: tailTip.x - 3.0, y: tailTip.y - 2.0 * signY))
        path.addLine(to: CGPoint(x: tailTip.x + 8.0, y: tailTip.y + 7.0 * signY))

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
        let fadeOut = SKAction.fadeOut(withDuration: 0.12)
        let scaleDown = SKAction.scale(to: 0.88, duration: 0.12)
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

#Preview("Crayon Dialogue Bubble Preview") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 520, height: 320))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.94, green: 0.94, blue: 0.93, alpha: 1.0)
        
        let config = SpeechBubbleConfig(
            text: "Lihat sketsa ini. Bagaimana kalau kita mencari tahu jalan di luar desa?",
            speaker: "Arthur",
            pageIndicator: "Ketuk untuk lanjut · 1/4",
            fontSize: 18,
            padding: CGSize(width: 32, height: 20),
            maxWidth: 380
        )
        
        let bubble = SpeechBubbleNode(config: config, tailTipOffset: CGPoint(x: -110, y: -55))
        bubble.position = CGPoint(x: 260, y: 160)
        scene.addChild(bubble)
        bubble.popIn()
        
        return scene
    }())
    .frame(width: 520, height: 320)
    .ignoresSafeArea()
}
#endif




