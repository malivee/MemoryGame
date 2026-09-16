// Penjelasan file: GameViewController.swift
// Menghubungkan layar UIKit dengan SpriteKit dan langsung menampilkan GameScene.
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as? SKView {
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = false
            view.showsNodeCount = false
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
