import SpriteKit
import UIKit

// Flow adapter. Gameplay rules live in Models and Systems.
extension DeckPuzzleScene {
    func changed(focusInventory: Bool = false) {
        let wasComplete = progress.assembled
        session.synchronize()
        if focusInventory, let selected, let index = state.inventory(progress: progress).firstIndex(of: selected) { inventoryPage = index / pageSize }
        PrologueStore.shared.save()
        rebuild(revealComplete: false)
        if progress.assembled { showAssembled(animated: !wasComplete) }
    }

    func enterSelected() {
        guard !enteringMemory, let view else { return }
        guard let id = selected else { message("Pilih keping dari rangkaian yang ingin dimasuki."); return }
        guard state.canEnter(id) else {
            message("Susun 3 keping dari map yang sama sesuai gambar dan putar hingga tegak.")
            return
        }
        guard state.worldEntry(for: id, progress: progress) != nil,
              let destination = PuzzleWorld.containing(id) else { return }
        let connected = state.connectedIDs(to: id)
        enteringMemory = true; dragPiece = nil
        session.synchronize(); PrologueStore.shared.save()
        let reduced = UIAccessibility.isReduceMotionEnabled
        let duration: TimeInterval = reduced ? 0.22 : 1.25
        let veil = SKSpriteNode(color: SKColor(red: 0.91, green: 0.89, blue: 0.83, alpha: 1), size: size)
        veil.position = CGPoint(x: size.width / 2, y: size.height / 2); veil.alpha = 0; veil.zPosition = 500
        safeAddChild(veil); veil.run(.fadeAlpha(to: 0.9, duration: duration))
        // Angkat seluruh rangkaian agar portal terasa berasal dari satu dunia, bukan satu keping.
        let members = connected.compactMap { tiles[$0] }
        let count = CGFloat(max(1, members.count))
        let center = CGPoint(x: members.reduce(CGFloat(0)) { $0 + $1.position.x } / count,
                             y: members.reduce(CGFloat(0)) { $0 + $1.position.y } / count)
        let origin = boardLayer.convert(center, to: self)
        if !reduced {
            let lift = SKNode(); lift.position = origin; lift.zPosition = 501
            lift.setScale(canvas.xScale * zoom); safeAddChild(lift)
            for member in members {
                let copy = member.copy() as! SKNode
                copy.position = CGPoint(x: member.position.x - center.x, y: member.position.y - center.y)
                lift.safeAddChild(copy)
            }
            let action = SKAction.group([
                .move(to: CGPoint(x: size.width / 2, y: size.height / 2), duration: duration),
                .scale(to: canvas.xScale * zoom * 2.6, duration: duration), .fadeOut(withDuration: duration)
            ])
            action.timingMode = .easeInEaseOut; lift.run(action)
            canvas.run(.fadeAlpha(to: 0.1, duration: duration))
        }
        MemoryPortal.play(on: self, origin: origin, inward: true, duration: duration)
        run(.sequence([.wait(forDuration: duration), .run { [weak self, weak view] in
            guard let self, let view, self.view === view else { return }
            let exploration = destination.makeScene(size: self.size)
            exploration.scaleMode = .resizeFill
            let transition = SKTransition.fade(with: SKColor(red: 0.87, green: 0.83, blue: 0.68, alpha: 1), duration: reduced ? 0.18 : 0.38)
            transition.pausesIncomingScene = false; transition.pausesOutgoingScene = false
            view.presentScene(exploration, transition: transition)
        }]), withKey: "enterMemory")
    }
}
