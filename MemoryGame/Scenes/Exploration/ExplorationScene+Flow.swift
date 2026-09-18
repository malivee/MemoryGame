import SpriteKit
import UIKit

// Flow adapter. Gameplay rules live in Models and Systems.
extension ExplorationScene {
    func returnToPhoto(selectedPiece: Int? = nil) {
        guard !watched && patrols.allSatisfy({ $0.suspicion == 0 }) else {
            say("Arthur masih diperhatikan. Berlindung sampai warga tenang."); return
        }
        PrologueStore.shared.save()
        let photo = RightDeckPuzzleScene(size: size)
        photo.bagSelectedPiece = selectedPiece
        photo.scaleMode = .resizeFill
        view?.presentScene(photo, transition: .fade(withDuration: 0.35))
    }

    func openBag() {
        guard bag == nil else { return }
        arthur.route.removeAll()
        stickTouch = nil; stickVector = .zero; stickKnob.position = stickCenter
        let overlay = BagOverlay(progress: progress, sceneSize: size)
        overlay.onClose = { [weak self] in self?.closeBag() }
        overlay.onUse = { [weak self] item in
            guard let self else { return }
            self.closeBag()
            switch item {
            case .book: self.openBook()
            case .fragment(let id): self.returnToPhoto(selectedPiece: id)
            }
        }
        bag = overlay
        addChild(overlay)
    }

    func closeBag() {
        bag?.removeFromParent()
        bag = nil
        lastTime = 0
    }

    func openBook() {
        guard progress.hasBook, !readingBook, let view else { return }
        readingBook = true
        PrologueStore.shared.save()
        arthur.route.removeAll()
        stickVector = .zero
        stickTouch = nil
        stickKnob.position = stickCenter
        let book = BookScene(size: size)
        book.scaleMode = .resizeFill
        // The book retains its return scene; an offscreen scene has no view.
        // Capture the presenting view weakly to avoid a view/scene retain cycle.
        book.onClose = { [self, weak view] in
            guard let view else { return }
            view.presentScene(self, transition: .fade(withDuration: 0.30))
        }
        view.presentScene(book, transition: .fade(withDuration: 0.30))
    }
}
