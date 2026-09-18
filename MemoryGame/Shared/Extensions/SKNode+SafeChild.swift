import SpriteKit

extension SKNode {
    func safeAddChild(_ node: SKNode) {
        if node.parent != self {
            node.removeFromParent()
            self.addChild(node)
        }
    }
}
