// Penjelasan file: PrologueUI.swift
// Helper SKNode untuk membuat label dan tombol dengan gaya prolog yang konsisten.
// Nama node membantu scene mengenali tombol; namedAncestor mencari nama pada node atau induknya.

import SpriteKit

extension SKNode {
    @discardableResult
    func storyLabel(_ text: String, at point: CGPoint, size: CGFloat = 16,
                    color: SKColor = .white, width: CGFloat = 0) -> SKLabelNode {
        let node = SKLabelNode(fontNamed: "AvenirNext-Medium")
        node.text = text
        node.fontSize = size
        node.fontColor = color
        node.position = point
        node.verticalAlignmentMode = .center
        if width > 0 { node.preferredMaxLayoutWidth = width; node.numberOfLines = 0 }
        addChild(node)
        return node
    }
    @discardableResult
    func storyButton(_ text: String, name: String, at point: CGPoint, width: CGFloat = 110) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: width, height: 42), cornerRadius: 12)
        button.position = point
        button.name = name
        button.fillColor = SKColor(red: 0.21, green: 0.29, blue: 0.28, alpha: 1)
        button.strokeColor = SKColor(white: 1, alpha: 0.2)
        let label = button.storyLabel(text, at: .zero, size: 14)
        label.name = name
        addChild(button)
        return button
    }
    func namedAncestor(prefix: String) -> String? {
        var current: SKNode? = self
        while let node = current {
            if let name = node.name, name.hasPrefix(prefix) { return name }
            current = node.parent
        }
        return nil
    }
}
