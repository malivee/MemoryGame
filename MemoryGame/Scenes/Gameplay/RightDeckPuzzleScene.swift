// Penjelasan file: RightDeckPuzzleScene.swift
// Alternative layout copied from GameScene: full-width board and fixed right-side deck.
// Layar utama papan jigsaw: menampilkan inventori, menerima drag, rotasi, dan pemilihan keping.
// Perubahan papan diteruskan ke model lalu disimpan; tombol Masuk memeriksa rangkaian minimal tiga keping.
// Scene ini juga menampilkan foto selesai dan animasi perpindahan menuju eksplorasi.

import SpriteKit
import UIKit

/// A 10-column by 4-row jigsaw photo, also used to enter the remembered locations.
final class RightDeckPuzzleScene: SKScene, UIGestureRecognizerDelegate {
    var progress: PrologueProgress { PrologueStore.shared.progress }
    var session: PuzzleSession { PuzzleSession(progress: progress) }
    var state: JigsawProgress { progress.jigsaw ?? JigsawProgress() }
    let textures = PuzzleTextureService()
    let canvas = SKNode()
    var tiles: [Int: SKNode] = [:]
    var hitPaths: [Int: CGPath] = [:]
    var renderScales: [Int: CGFloat] = [:]
    var selected: Int?
    var board = CGRect.zero
    var boardScale: CGFloat = 1
    var cell = CGSize.zero
    var inventoryPage = 0
    let pageSize = 5
    var dragPiece: Int?
    var dragStart = CGPoint.zero
    var dragHome = CGPoint.zero
    var moved = false
    var enteringMemory = false
    let boardLayer = SKNode()
    var viewport = CGRect.zero
    var zoom: CGFloat = 1
    var cameraOffset = CGPoint.zero
    var gestures: [UIGestureRecognizer] = []
    var halfWidth: CGFloat = 500
    var deckBounds = CGRect.zero
    let fixedDeckWidth: CGFloat = 185
    var entryVisible = false
    var rotatingPiece: Int?
    var rotationStart: CGFloat = 0
    var trackedTouch: UITouch?
    var bagSelectedPiece: Int?
    
    // Memuat progres, menyiapkan puzzle, lalu membangun papan saat scene dibuka.
    override func didMove(to view: SKView) {
        // Background kekuningan / krem hangat
        backgroundColor = SKColor(red: 0.91, green: 0.89, blue: 0.83, alpha: 1.0)
        progress.prepareJigsaw()
        PrologueStore.shared.save()
        canvas.removeFromParent()
        addChild(canvas)
        if let id = bagSelectedPiece {
            selected = id
            if let index = state.inventory(progress: progress).firstIndex(of: id) { inventoryPage = index / pageSize }
            bagSelectedPiece = nil
        }
        layoutPhoto()
        installGestures(on: view)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        guard canvas.parent != nil, !enteringMemory else { return }
        dragPiece = nil
        layoutPhoto()
    }

    var allowsBoardGestures: Bool {
        !enteringMemory && rotatingPiece == nil
    }

    override func willMove(from view: SKView) {
        gestures.forEach { view.removeGestureRecognizer($0) }
        gestures.removeAll()
    }

}
