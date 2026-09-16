//
//  AudioService.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import AudioToolbox
import Foundation

final class AudioService {
    static let shared = AudioService()

    private init() {}

    func playSound(named name: String) {
        // Hook AVFoundation asset playback here when custom sound files are added.
    }

    func playSystemSound(id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }
}
