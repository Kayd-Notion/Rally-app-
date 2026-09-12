import SwiftUI

/// L'écran principal : le feed éphémère.
/// Les posts remontent selon leur score (fraîcheur + boost) et disparaissent
/// quand leur compte à rebours atteint zéro.
struct FeedView: View {
    @EnvironmentObject var store: RallyStore
    @State private var showComposer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(store.liveFeed) { post in
                        PostCardView(post: post)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
                .animation(.default, value: store.liveFeed.map(\.id))
            }
            .background(Theme.background)
            .navigationTitle("Rally")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { walletChip }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showComposer = true } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showComposer) {
                ComposerView().environmentObject(store)
            }
        }
        .tint(Theme.accent)
    }

    private var walletChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "wallet.bifold.fill").font(.system(size: 11))
            Text(Format.crypto(store.walletBalance))
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Theme.surface, in: Capsule())
    }
}

/// Petit composer pour publier un post de démo.
struct ComposerView: View {
    @EnvironmentObject var store: RallyStore
    @Environment(\.dismiss) var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Quoi de neuf ? (ça disparaîtra bientôt…)",
                          text: $text, axis: .vertical)
                    .font(.system(size: 18))
                    .padding()
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .background(Theme.background)
            .navigationTitle("Nouveau post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publier") {
                        store.createPost(text: text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .tint(Theme.accent)
    }
}
