import SpriteKit

/// Modal bag shared by the photo and exploration screens. All touches are
/// consumed here; the owner pauses gameplay until the bag has been dismissed.
final class BagOverlay: SKNode {
    var onClose: (() -> Void)?
    var onUse: ((BagItem) -> Void)?
    let inventory: BagInventory
    let textures = PuzzleTextureService()
    let panel = SKNode()
    let details = SKNode()
    var page = 0
    var selected: BagItem?
    var pressed: String?
    let gold = SKColor(red: 0.74, green: 0.58, blue: 0.32, alpha: 1)
    let cream = SKColor(red: 0.91, green: 0.82, blue: 0.63, alpha: 1)

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

}
