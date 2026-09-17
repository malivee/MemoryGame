import Foundation

public enum QTEHitResult: Equatable, Sendable { case miss, good, great }

public struct QuickTimeEventConfig: Sendable {
    public let radius: CGFloat
    public let requiredTaps: Int
    public let buttonPrompt: String
    public let allowTouchAnywhere: Bool
    public let autoDismissDelay: TimeInterval

    public init(radius: CGFloat = 86, requiredTaps: Int = 18,
                buttonPrompt: String = "TAP", allowTouchAnywhere: Bool = false,
                autoDismissDelay: TimeInterval = 1.2) {
        self.radius = radius.isFinite ? max(78, radius) : 86
        self.requiredTaps = max(1, requiredTaps)
        self.buttonPrompt = buttonPrompt
        self.allowTouchAnywhere = allowTouchAnywhere
        self.autoDismissDelay = autoDismissDelay.isFinite ? max(0, autoDismissDelay) : 1.2
    }
}

/// Every discrete press adds one point. Only reaching the target completes the QTE.
public struct QuickTimeEventLogic {
    public let config: QuickTimeEventConfig
    public private(set) var tapCount = 0
    public private(set) var isCompleted = false
    public private(set) var isSuccess = false
    public var currentProgress: CGFloat { CGFloat(tapCount) / CGFloat(config.requiredTaps) }

    public init(config: QuickTimeEventConfig = QuickTimeEventConfig()) { self.config = config }

    public mutating func registerTap() -> (result: QTEHitResult, completed: Bool, isSuccess: Bool) {
        guard !isCompleted else { return (.miss, true, isSuccess) }
        tapCount += 1
        if tapCount >= config.requiredTaps {
            isCompleted = true
            isSuccess = true
        }
        return (isSuccess ? .great : .good, isCompleted, isSuccess)
    }

}
