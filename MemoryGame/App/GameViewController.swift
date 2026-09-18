// Penjelasan file: GameViewController.swift
// Menghubungkan layar UIKit dengan SpriteKit dan memulai cutscene sebelum GameScene.
// Mengatur ukuran scene, orientasi landscape, serta tampilan status bar dan indikator debug.

//
//  GameViewController.swift
//  MemoryGame
//
//  Created by Muhammad Alief Rahman Fardillah on 15/09/26.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    private var hasPresentedInitialScene = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasPresentedInitialScene, let view = self.view as? SKView, view.bounds.width > 0 else { return }
        hasPresentedInitialScene = true
        
        let hasSeenCutscene = UserDefaults.standard.bool(forKey: "hasSeenOpeningCutscene")
        let scene: SKScene
        if hasSeenCutscene {
            let puzzle = RightDeckPuzzleScene(size: view.bounds.size)
            puzzle.scaleMode = .resizeFill
            scene = puzzle
        } else {
            let cutscene = OpeningCutsceneScene(size: view.bounds.size)
            cutscene.scaleMode = .resizeFill
            scene = cutscene
        }
        view.presentScene(scene)
        
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
