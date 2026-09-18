import UIKit
import SpriteKit

/// Prototype pages are rasterized once so the ink bends with the existing paper animation.
final class JournalPageArtwork {
    private struct Page {
        let entry: IsoldeJournalEntry
        var text = ""
        var illustration: String?
        var scribbles = false
        var heading = false
    }
    private var pages: [Page] = []
    private var cache: [Int: SKTexture] = [:]
    private let paperSize = CGSize(width: 500, height: 532)
    private let textRect = CGRect(x: 55, y: 88, width: 390, height: 389)
    private let illustratedTextRect = CGRect(x: 55, y: 346, width: 390, height: 131)
    private let font = UIFont(name: "Noteworthy-Light", size: 21)
        ?? UIFont(name: "BradleyHandITCTT-Bold", size: 21)
        ?? .italicSystemFont(ofSize: 21)
    private var paragraph: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 9
        style.lineSpacing = 1
        return style
    }
    private var textAttributes: [NSAttributedString.Key: Any] {
        [.font: font, .paragraphStyle: paragraph]
    }
    var spreadCount: Int { pages.count / 2 }

    init() {
        for entry in IsoldeJournalEntry.entries {
            if entry.localLanguage {
                pages.append(Page(entry: entry, scribbles: true))
                pages.append(Page(entry: entry, illustration: entry.illustration, scribbles: true))
            } else if entry.journal.isEmpty {
                pages.append(Page(entry: entry))
                pages.append(Page(entry: entry, illustration: entry.illustration))
            } else {
                var remaining = entry.journal
                var first = true
                while !remaining.isEmpty {
                    let illustration = !first && pages.count % 2 == 1 ? entry.illustration : nil
                    let rect = illustration == nil ? textRect : illustratedTextRect
                    let chunk = takeText(from: &remaining, fitting: rect)
                    pages.append(Page(entry: entry, text: chunk, illustration: illustration, heading: first))
                    first = false
                    // Illustration appears once, on the first right-hand page.
                    if pages.count % 2 == 0 { break }
                }
                while !remaining.isEmpty {
                    pages.append(Page(entry: entry, text: takeText(from: &remaining, fitting: textRect)))
                }
                if pages.last?.heading == true, let illustration = entry.illustration {
                    pages.append(Page(entry: entry, illustration: illustration))
                }
            }
            // Start each new record on a fresh spread.
            if pages.count % 2 != 0 { pages.append(Page(entry: entry)) }
        }
    }

    private func takeText(from remaining: inout String, fitting rect: CGRect) -> String {
        let words = remaining.components(separatedBy: " ")
        var chunk = ""
        var consumed = 0
        for word in words {
            let candidate = chunk.isEmpty ? word : chunk + " " + word
            let height = (candidate as NSString).boundingRect(
                with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: textAttributes, context: nil).height
            if ceil(height) > rect.height && consumed > 0 { break }
            chunk = candidate
            consumed += 1
        }
        remaining = words.dropFirst(consumed).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return chunk.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func texture(side: BookPageSide, spread: Int) -> SKTexture {
        let index = spread * 2 + (side == .left ? 0 : 1)
        if let cached = cache[index] { return cached }
        let page = pages[index]
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: paperSize, format: format).image { renderer in
            let ctx = renderer.cgContext
            UIColor(red: 0.88, green: 0.82, blue: 0.65, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: paperSize))
            // Deterministic grain and softened margins; no old manuscript text shows through.
            for i in 0..<1600 {
                let x = CGFloat((i * 137 + 29) % 500)
                let y = CGFloat((i * 83 + 11) % 532)
                ctx.setFillColor(UIColor(white: 0.25, alpha: 0.025).cgColor)
                ctx.fillEllipse(in: CGRect(x: x, y: y, width: 2, height: 1))
            }
            for i in 0..<20 {
                ctx.setStrokeColor(UIColor(red: 0.39, green: 0.29, blue: 0.12, alpha: 0.018).cgColor)
                ctx.stroke(CGRect(x: CGFloat(i), y: CGFloat(i), width: 500 - CGFloat(i * 2), height: 532 - CGFloat(i * 2)))
            }
            let ink = UIColor(red: 0.24, green: 0.19, blue: 0.12, alpha: 1)
            if page.heading {
                (page.entry.title as NSString).draw(in: CGRect(x: 55, y: 37, width: 390, height: 45), withAttributes: [
                    .font: font.withSize(24), .foregroundColor: ink])
            } else if page.scribbles {
                scribble(in: CGRect(x: 46, y: 46, width: 255, height: 30), seed: index + 9, context: ctx)
            }
            if page.scribbles {
                scribble(in: page.illustration == nil ? textRect : illustratedTextRect, seed: index, context: ctx)
            } else if !page.text.isEmpty {
                var attributes = textAttributes
                attributes[.foregroundColor] = ink
                (page.text as NSString).draw(in: page.illustration == nil ? textRect : illustratedTextRect, withAttributes: attributes)
            }
            if let illustration = page.illustration {
                let rect = CGRect(x: 55, y: 72, width: 390, height: 250)
                ctx.setStrokeColor(ink.withAlphaComponent(0.4).cgColor)
                ctx.setLineWidth(1.5)
                ctx.setLineDash(phase: 0, lengths: [6, 5])
                ctx.stroke(rect)
                ctx.setLineDash(phase: 0, lengths: [])
                ctx.move(to: rect.origin); ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                ctx.move(to: CGPoint(x: rect.maxX, y: rect.minY)); ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                ctx.setAlpha(0.18); ctx.strokePath(); ctx.setAlpha(1)
                let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
                let label = "[Sketch]\n" + illustration
                (label as NSString).draw(in: CGRect(x: 78, y: 150, width: 344, height: 150), withAttributes: [
                    .font: font.withSize(19), .foregroundColor: ink, .paragraphStyle: paragraph])
            }
            ("\(index + 1)" as NSString).draw(at: CGPoint(x: 242, y: 499), withAttributes: [
                .font: font.withSize(14), .foregroundColor: ink.withAlphaComponent(0.6)])
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        cache[index] = texture
        return texture
    }

    private func scribble(in rect: CGRect, seed: Int, context: CGContext) {
        context.setStrokeColor(UIColor(red: 0.25, green: 0.19, blue: 0.12, alpha: 0.8).cgColor)
        context.setLineWidth(1.6)
        context.setLineCap(.round)
        for line in 0..<Int(rect.height / 24) {
            let y = rect.minY + CGFloat(line) * 24 + 13
            var x = rect.minX
            let end = rect.maxX - CGFloat((line * 31 + seed * 17) % 75)
            while x < end - 30 {
                let length = CGFloat(20 + (line * 7 + Int(x) + seed * 13) % 35)
                context.move(to: CGPoint(x: x, y: y))
                for stroke in 0..<5 {
                    let next = x + length * CGFloat(stroke + 1) / 5
                    let rise = CGFloat((stroke * 11 + line * 3 + seed) % 15) - 8
                    context.addCurve(to: CGPoint(x: next, y: y + rise / 3),
                        control1: CGPoint(x: next - 6, y: y - 11 + rise),
                        control2: CGPoint(x: next - 9, y: y + 9))
                }
                context.strokePath()
                x += length + 9
            }
        }
    }
}
