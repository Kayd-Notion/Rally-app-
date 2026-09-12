import SwiftUI

/// Profil de l'utilisateur courant : son wallet simulé et ses posts encore vivants.
struct ProfileView: View {
    @EnvironmentObject var store: RallyStore

    private var myLivePosts: [Post] {
        store.posts.filter {
            $0.author.id == store.currentUser.id && BoostEngine.isAlive($0, at: store.now)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    walletCard
                    if myLivePosts.isEmpty {
                        Text("Tes posts apparaîtront ici — le temps qu'ils vivent.")
                            .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(myLivePosts) { PostCardView(post: $0) }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 90)
            }
            .background(Theme.background)
            .navigationTitle(store.currentUser.displayName)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .tint(Theme.accent)
    }

    private var walletCard: some View {
        VStack(spacing: 14) {
            Image(systemName: store.currentUser.avatarSystemName)
                .font(.system(size: 34)).foregroundStyle(Theme.accent)
                .frame(width: 72, height: 72)
                .background(Theme.surfaceElevated, in: Circle())
            Text(store.currentUser.handle).font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 2) {
                Text("Wallet (démo)").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text(Format.crypto(store.walletBalance))
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.accent)
            }

            Button { store.topUp() } label: {
                Text("Recharger +25")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Theme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24).frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24))
    }
}
