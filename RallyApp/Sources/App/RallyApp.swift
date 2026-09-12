import SwiftUI

/// Point d'entrée de l'app. On instancie le store une seule fois et on l'injecte
/// dans toute la hiérarchie via l'environnement.
@main
struct RallyApp: App {
    @StateObject private var store = RallyStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
