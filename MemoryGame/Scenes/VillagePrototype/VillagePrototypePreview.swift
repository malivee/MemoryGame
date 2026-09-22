// Penjelasan file: VillagePrototypePreview.swift
// Xcode Canvas menjalankan preview terpisah tanpa mengubah entry point atau save aplikasi.
#if DEBUG
import SwiftUI
import SpriteKit
struct VillagePrototypePreview: UIViewRepresentable {
    var access: VillageAccess = .opening
    func makeUIView(context: Context) -> SKView {
        let defaultSize = CGSize(width: 844, height: 390)
        let view = SKView(frame: CGRect(origin: .zero, size: defaultSize))
        let scene = VillagePrototypeScene(size: defaultSize)
        scene.access = access
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        return view
    }
    func updateUIView(_ view: SKView, context: Context) {}
}
struct VillageCartoPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let defaultSize = CGSize(width: 844, height: 390)
        let view = SKView(frame: CGRect(origin: .zero, size: defaultSize))
        let scene = VillageCartoScene(size: defaultSize)
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        return view
    }
    func updateUIView(_ view: SKView, context: Context) {}
}

struct VillagePrototypePreviewProvider: PreviewProvider {
    static var previews: some View {
        Group {
            VillageCartoPreview()
                .previewDisplayName("Carto Map & Buildings")
                .ignoresSafeArea()
                .previewInterfaceOrientation(.landscapeLeft)

            VillagePrototypePreview()
                .previewDisplayName("Village Story Scene")
                .ignoresSafeArea()
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}
#endif
