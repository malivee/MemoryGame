//
//  VillageOpeningState.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 21/09/26.
//


// Menyimpan prasyarat tutorial tanpa menggeser ID cerita
// atau hadiah kepingan puzzle.

import Foundation

struct VillageOpeningState: Codable {
    var collectedWater = false
    var spokeToMara = false
}

extension StoryProgression {
    static func needsWellWater(
        _ progress: PrologueProgress
    ) -> Bool {
        progress.storyProgress == 0 &&
        progress.villageOpening?.collectedWater != true
    }

    static func canStartMaraQTE(
        _ progress: PrologueProgress
    ) -> Bool {
        currentStep(for: progress)?.minigame == .maraShelfQTE &&
        progress.villageOpening?.collectedWater == true &&
        progress.villageOpening?.spokeToMara == true
    }

    @discardableResult
    static func collectWellWater(
        in progress: PrologueProgress
    ) -> Bool {
        guard needsWellWater(progress) else {
            return false
        }

        var opening = progress.villageOpening
            ?? VillageOpeningState()

        opening.collectedWater = true
        progress.villageOpening = opening

        return true
    }

    @discardableResult
    static func finishMaraIntroduction(
        in progress: PrologueProgress
    ) -> Bool {
        guard progress.storyProgress == 0,
              !needsWellWater(progress) else {
            return false
        }

        var opening = progress.villageOpening
            ?? VillageOpeningState()

        opening.spokeToMara = true
        progress.villageOpening = opening

        return true
    }
}