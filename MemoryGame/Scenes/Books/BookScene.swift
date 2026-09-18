import SpriteKit

/// A bound manuscript. Page artwork is kept separate from the binding so each
/// leaf can bend around the gutter without moving the rest of the book.
final class BookScene: SKScene {
    let journalArtwork = JournalPageArtwork()
    var maximumFlipCount: Int { journalArtwork.spreadCount - 1 }
    var onClose: (() -> Void)?
    var flipCount = 0
    var touchStartPoint: CGPoint?
    var trackedTouch: UITouch?
    let bookNode = SKNode()
    var leftPageNode = SKSpriteNode()
    var rightPageNode = SKSpriteNode()
    var turningPage: SKSpriteNode?
    var turnShadow: SKSpriteNode?
    var turnDirection: BookFlipDirection?
    var turnStartTime: TimeInterval?
    let turnDuration: TimeInterval = 1.15
    let counterLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    let promptLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
    let closeButtonName = "bookClose"
    let turnAmount = SKUniform(name: "u_turn", float: 0)
    lazy var paperShader = SKShader(source: """
        void main() {
            vec4 paper = SKDefaultShading();
            float lift = sin(u_turn * 3.14159265);
            float across = v_tex_coord.x;
            float roll = 0.5 + 0.5 * cos(across * 3.14159265);
            float light = 1.0 - lift * (0.12 + 0.22 * roll);
            gl_FragColor = vec4(paper.rgb * light, paper.a);
        }
        """, uniforms: [turnAmount])

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.075, green: 0.065, blue: 0.05, alpha: 1)
        buildScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        // Finish the logical turn before rebuilding for a new viewport.
        finishTurn()
        buildScene()
    }

    var pageSize: CGSize {
        let book = currentBookSize()
        return CGSize(width: book.width / 2, height: book.height)
    }

}

enum BookPageSide { case left, right }
enum BookFlipDirection { case forward, backward }
