import SwiftUI

/// La barre d'onglets : Feed, Classement, Profil.
struct RootTabView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Feed", systemImage: "bolt.horizontal.fill") }
            RankingsView()
                .tabItem { Label("Classement", systemImage: "trophy.fill") }
            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.fill") }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
    }
}
