import SpriteKit

/// Modal bag shared by the photo and exploration screens. All touches are
/// consumed here; the owner pauses gameplay until the bag has been dismissed.
final class BagOverlay: SKNode {
    var onClose: (() -> Void)?
    var onUse: ((BagItem) -> Void)?
    private let inventory: BagInventory
    private let textures = PuzzleTextureService()
    private let panel = SKNode()
    private let details = SKNode()
    private var page = 0
    private var selected: BagItem?
    private var pressed: String?
    private let gold = SKColor(red: 0.74, green: 0.58, blue: 0.32, alpha: 1)
    private let cream = SKColor(red: 0.91, green: 0.82, blue: 0.63, alpha: 1)

    init(progress: PrologueProgress, sceneSize: CGSize) {
        inventory = BagInventory(progress: progress)
        super.init()
        isUserInteractionEnabled = true
        zPosition = 1000
        let shade = SKSpriteNode(color: SKColor(white: 0, alpha: 0.72), size: CGSize(width: 4000, height: 4000))
        shade.zPosition = -10
        addChild(shade)
        panel.position.x = 130
        details.position = CGPoint(x: -215, y: 0)
        addChild(panel); addChild(details)
        resize(to: sceneSize)
        rebuild()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func resize(to size: CGSize) {
        position = CGPoint(x: size.width / 2, y: size.height / 2)
        setScale(min((size.width - 48) / 650, (size.height - 24) / 556))
    }
    @discardableResult
    private func box(_ size: CGSize, at point: CGPoint, fill: SKColor, stroke: SKColor, in parent: SKNode, radius: CGFloat = 3) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.position = point; node.fillColor = fill; node.strokeColor = stroke
        node.lineWidth = 1.5; parent.addChild(node)
        return node
    }
    @discardableResult
    private func label(_ text: String, at point: CGPoint, size: CGFloat, in parent: SKNode, width: CGFloat = 0) -> SKLabelNode {
        let node = SKLabelNode(fontNamed: "Georgia")
        node.text = text; node.fontSize = size; node.fontColor = cream
        node.position = point; node.verticalAlignmentMode = .center
        if width > 0 { node.preferredMaxLayoutWidth = width; node.numberOfLines = 0 }
        parent.addChild(node)
        return node
    }
    private func button(_ text: String, name: String, at point: CGPoint, width: CGFloat, in parent: SKNode) {
        let node = box(CGSize(width: width, height: 42), at: point,
                       fill: SKColor(red: 0.25, green: 0.16, blue: 0.09, alpha: 1), stroke: gold, in: parent)
        node.name = name
        label(text, at: .zero, size: 16, in: node)
    }
    private func rebuild() {
        panel.removeAllChildren()
        let dark = SKColor(red: 0.11, green: 0.065, blue: 0.035, alpha: 1)
        box(CGSize(width: 344, height: 544), at: .zero, fill: dark, stroke: .black, in: panel, radius: 9)
        box(CGSize(width: 328, height: 530), at: .zero,
            fill: SKColor(red: 0.20, green: 0.12, blue: 0.065, alpha: 1), stroke: gold.withAlphaComponent(0.65), in: panel)
        // Worn leather grain and stitching remain sharp at any screen scale.
        for i in 0..<95 {
            let y = -253 + CGFloat(i) * 5.3
            let grain = box(CGSize(width: 309, height: 1), at: CGPoint(x: 0, y: y),
                            fill: SKColor(white: i % 3 == 0 ? 1 : 0, alpha: 0.035), stroke: .clear, in: panel)
            grain.zRotation = CGFloat(i % 5 - 2) * 0.001
        }
        for y in stride(from: -244, through: 244, by: 22) {
            for x in [-157, 157] {
                box(CGSize(width: 5, height: 9), at: CGPoint(x: x, y: y), fill: gold.withAlphaComponent(0.45), stroke: .clear, in: panel)
            }
        }
        label("Items Bag", at: CGPoint(x: -20, y: 229), size: 26, in: panel)
        button("×", name: "close", at: CGPoint(x: 128, y: 232), width: 40, in: panel)
        label("\(inventory.items.count) item · Tas Arthur", at: CGPoint(x: 0, y: 194), size: 12, in: panel)
        let visible = inventory.items(on: page)
        for slot in 0..<BagInventory.slotsPerPage {
            let item = slot < visible.count ? visible[slot] : nil
            let point = CGPoint(x: -116 + CGFloat(slot % 5) * 58, y: 151 - CGFloat(slot / 5) * 58)
            let node = box(CGSize(width: 56, height: 56), at: point,
                           fill: item == selected && item != nil ? SKColor(red: 0.34, green: 0.25, blue: 0.10, alpha: 1) : dark,
                           stroke: item == selected && item != nil ? gold : SKColor(red: 0.32, green: 0.22, blue: 0.13, alpha: 1), in: panel, radius: 0)
            node.name = "slot-\(slot)"
            guard let item else { continue }
            addIcon(item, to: node, size: 42)
            let count = label("1", at: CGPoint(x: 19, y: -18), size: 12, in: node)
            count.fontColor = .white
        }
        button("‹", name: "previous", at: CGPoint(x: -113, y: -190), width: 48, in: panel)
        button("›", name: "next", at: CGPoint(x: 113, y: -190), width: 48, in: panel)
        panel.childNode(withName: "previous")?.alpha = page > 0 ? 1 : 0.3
        panel.childNode(withName: "next")?.alpha = page + 1 < inventory.pageCount ? 1 : 0.3
        label("Halaman \(page + 1) / \(inventory.pageCount)", at: CGPoint(x: 0, y: -190), size: 14, in: panel)
        label("Pilih item untuk melihat detail", at: CGPoint(x: 0, y: -239), size: 12, in: panel)
        rebuildDetails()
    }
    private func addIcon(_ item: BagItem, to parent: SKNode, size: CGFloat) {
        switch item {
        case .book:
            let cover = box(CGSize(width: size * 0.72, height: size * 0.9), at: .zero,
                            fill: SKColor(red: 0.39, green: 0.17, blue: 0.075, alpha: 1), stroke: gold, in: parent)
            cover.zRotation = -0.13
            box(CGSize(width: size * 0.06, height: size * 0.84), at: CGPoint(x: -size * 0.25, y: 0), fill: gold, stroke: .clear, in: cover)
            label("✦", at: .zero, size: size * 0.40, in: cover)
        case .fragment(let id):
            let data = JigsawCatalog.data(for: id)
            let icon = SKSpriteNode(texture: textures.texture(for: data, dryVariant: id == JigsawCatalog.dryLakeID))
            let scale = size / max(data.width, data.height)
            icon.size = CGSize(width: data.width * scale, height: data.height * scale)
            parent.addChild(icon)
        }
    }
    private func rebuildDetails() {
        details.removeAllChildren()
        box(CGSize(width: 260, height: 360), at: .zero,
            fill: SKColor(red: 0.12, green: 0.08, blue: 0.05, alpha: 0.98), stroke: gold.withAlphaComponent(0.6), in: details, radius: 7)
        guard let item = selected else {
            label("Tas perjalanan", at: CGPoint(x: 0, y: 85), size: 23, in: details)
            label(inventory.items.isEmpty ? "Tas masih kosong. Temukan buku dan kepingan dalam perjalanan Arthur." : "Buku dan kepingan yang kamu peroleh tersimpan di sini. Ketuk salah satu slot untuk memilih item.",
                  at: CGPoint(x: 0, y: 0), size: 16, in: details, width: 214)
            label("Item mengikuti progres tersimpan", at: CGPoint(x: 0, y: -125), size: 11, in: details)
            return
        }
        let icon = SKNode(); icon.position.y = 116; details.addChild(icon)
        addIcon(item, to: icon, size: 60)
        label(item.category, at: CGPoint(x: 0, y: 66), size: 10, in: details)
        label(item.title, at: CGPoint(x: 0, y: 32), size: 21, in: details, width: 226)
        label(item.detail, at: CGPoint(x: 0, y: -42), size: 15, in: details, width: 216)
        button(item == .book ? "Buka buku" : "Pilih di puzzle", name: "use", at: CGPoint(x: 0, y: -133), width: 212, in: details)
    }
    private func action(at point: CGPoint) -> String? {
        for node in nodes(at: point) {
            var current: SKNode? = node
            while let candidate = current, candidate !== self {
                if let name = candidate.name { return name }
                current = candidate.parent
            }
        }
        return nil
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        pressed = action(at: touch.location(in: self))
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { pressed = nil }
        guard let touch = touches.first, let pressed, pressed == action(at: touch.location(in: self)) else { return }
        if pressed == "close" { onClose?(); return }
        if pressed == "previous", page > 0 { page -= 1; rebuild(); return }
        if pressed == "next", page + 1 < inventory.pageCount { page += 1; rebuild(); return }
        if pressed == "use", let selected { onUse?(selected); return }
        if pressed.hasPrefix("slot-"), let slot = Int(pressed.dropFirst(5)) {
            let visible = inventory.items(on: page)
            selected = visible.indices.contains(slot) ? visible[slot] : nil
            HapticsService.shared.playSelection()
            rebuild()
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { pressed = nil }
}
