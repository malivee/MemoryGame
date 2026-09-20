import SpriteKit

public extension SKAction {
    /// Allows fluent chaining to set the timing mode of an SKAction.
    @discardableResult
    func applyTimingMode(_ mode: SKActionTimingMode) -> SKAction {
        self.timingMode = mode
        return self
    }
}
