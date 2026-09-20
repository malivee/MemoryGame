// Penjelasan file: VillagePrototypePreview.swift
// Xcode Canvas menjalankan preview terpisah tanpa mengubah entry point atau save aplikasi.
#if DEBUG
import SwiftUI
import SpriteKit
struct VillagePrototypePreview: UIViewRepresentable {
    var access: VillageAccess = .wholeVillage
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        let scene = VillagePrototypeScene(size: view.bounds.size)
        scene.access = access
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        return view
    }
    func updateUIView(_ view: SKView, context: Context) {}
}
struct VillagePrototypePreviewProvider: PreviewProvider {
    static var previews: some View {
        VillagePrototypePreview().ignoresSafeArea().previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
