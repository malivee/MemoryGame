// Penjelasan file: HapticsService.swift
// Menyediakan getaran sentuhan iOS untuk pemilihan, benturan, dan notifikasi.
// Setiap fungsi membuat generator UIKit sesuai jenis umpan balik yang diminta.

//
//  HapticsService.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
//

#if canImport(UIKit)
import UIKit
#endif

final class HapticsService {
    static let shared = HapticsService()

    private init() {}

    func playSelection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    #if canImport(UIKit)
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    #else
    func playImpact(style: Any = 0) {}
    func playNotification(_ type: Any = 0) {}
    #endif
}

