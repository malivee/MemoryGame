// Penjelasan file: HapticsService.swift
// Menyediakan getaran sentuhan iOS untuk pemilihan, benturan, dan notifikasi.
// Setiap fungsi membuat generator UIKit sesuai jenis umpan balik yang diminta.

//
//  HapticsService.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
//

import UIKit

final class HapticsService {
    static let shared = HapticsService()

    private init() {}

    func playSelection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
