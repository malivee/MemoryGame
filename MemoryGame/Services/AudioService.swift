// Penjelasan file: AudioService.swift
// Layanan bersama untuk suara. playSystemSound memutar suara sistem melalui AudioToolbox.
// playSound(named:) masih berupa tempat pengembangan dan belum memutar berkas audio kustom.

//
//  AudioService.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
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
