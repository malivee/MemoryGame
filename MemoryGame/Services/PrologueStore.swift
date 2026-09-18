import Foundation

final class PrologueStore {
    static let shared = PrologueStore()
    private static let key = "memory.prologue.v1"
    private(set) var progress: PrologueProgress
    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(PrologueProgress.self, from: data) {
            progress = saved
        } else { progress = PrologueProgress() }
    }
    // Mengubah progres menjadi JSON dan menyimpannya di UserDefaults perangkat.
    func save() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
    // Mengganti progres dengan kondisi awal lalu menyimpannya; dipanggil setelah konfirmasi pengguna.
    func restart() { progress = PrologueProgress(); save() }
}
