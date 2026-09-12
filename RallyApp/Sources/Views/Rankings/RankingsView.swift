import SwiftUI

/// Les classements "du moment". Deux portées : Monde et Pays.
/// On ne classe QUE les pumps reçus dans la fenêtre `rankingWindow` → un
/// classement qui bouge sans arrêt, jamais "de tous les temps". C'est le moteur
/// de FOMO : ce que tu vois là n'existera plus dans une heure.
struct RankingsView: View {
    @EnvironmentObject var store: RallyStore

    enum Scope: String, CaseIterable { case monde = "Monde", pays = "Pays" }
    @State private var scope: Scope = .monde
    @State private var country = "FR"

    private var ranked: [Post] {
        switch scope {
        case .monde: return store.globalRanking()
        case .pays:  return store.countryRanking(country)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Portée", selection: $scope) {
                    ForEach(Scope.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                if scope == .pays { countryPicker }

                fomoBanner

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(ranked.enumerated()), id: \.element.id) { idx, post in
                            PostCardView(post: post, rank: idx + 1)
                        }
                        if ranked.isEmpty { emptyState }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 90)
                    .animation(.default, value: ranked.map(\.id))
                }
            }
            .padding(.top, 8)
            .background(Theme.background)
            .navigationTitle("Classement")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .tint(Theme.accent)
    }

    private var countryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.availableCountries, id: \.self) { code in
                    Button { country = code } label: {
                        Text("\(flag(code)) \(code)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(country == code ? .black : Theme.textPrimary)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(country == code ? AnyShapeStyle(Theme.accent)
                                        : AnyShapeStyle(Theme.surface), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var fomoBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill").foregroundStyle(Theme.urgent)
            Text("Classement des \(Format.countdown(RallyConfig.rankingWindow)) qui viennent de s'écouler — ça bouge en temps réel")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy").font(.system(size: 32))
                .foregroundStyle(Theme.textSecondary)
            Text("Personne n'a encore pumpé ici récemment.\nSois le premier à faire monter quelqu'un.")
                .font(.system(size: 14)).multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 60)
    }
}
