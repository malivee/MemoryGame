// Penjelasan file: GameScene.swift
// Layar utama papan jigsaw: menampilkan inventori, menerima drag, rotasi, dan pemilihan keping.
// Perubahan papan diteruskan ke model lalu disimpan; tombol Masuk memeriksa rangkaian minimal tiga keping.
// Scene ini juga menampilkan foto selesai dan animasi perpindahan menuju eksplorasi.

import SpriteKit
import UIKit

/// A 10-column by 4-row jigsaw photo, also used to enter the remembered locations.
final class GameScene: SKScene {
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
    let pageSize = 10
    var dragPiece: Int?
    var dragStart = CGPoint.zero
    var dragHome = CGPoint.zero
    var moved = false
    var confirmingRestart = false
    var enteringMemory = false
    var bag: BagOverlay?
    var qte: QuickTimeEventNode?
    var bagSelectedPiece: Int?

    // Memuat progres, menyiapkan puzzle, lalu membangun papan saat scene dibuka.
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.12, blue: 0.14, alpha: 1)
        progress.prepareJigsaw()
        PrologueStore.shared.save()
        if canvas.parent == nil { addChild(canvas) }
        if let id = bagSelectedPiece {
            selected = id
            if let index = state.inventory(progress: progress).firstIndex(of: id) { inventoryPage = index / pageSize }
            bagSelectedPiece = nil
        }
        layoutPhoto()
    }
    override func didChangeSize(_ oldSize: CGSize) {
        qte?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        guard canvas.parent != nil, !enteringMemory else { return }
        dragPiece = nil
        layoutPhoto()
        bag?.resize(to: size)
    }

    var worldGroups: [Set<Int>] { state.enterableGroups }

}
