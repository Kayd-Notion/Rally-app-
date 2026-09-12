import SwiftUI

/// Une carte de post dans le feed.
/// Elle lit l'horloge du store (`store.now`) pour recalculer en direct le temps
/// restant, le boost, et la "chaleur" du post.
struct PostCardView: View {
    @EnvironmentObject var store: RallyStore
    let post: Post
    var rank: Int? = nil          // position dans un classement, si affichée là

    @State private var showPump = false

    private var now: Date { store.now }
    private var boost: Double { BoostEngine.liveBoost(of: post, at: now) }
    private var remaining: TimeInterval { BoostEngine.timeRemaining(of: post, at: now) }
    private var lifeFraction: Double { BoostEngine.lifeFraction(of: post, at: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Text(post.text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            footer
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(boost > 0 ? Theme.accent.opacity(0.35) : .clear, lineWidth: 1)
        )
        .sheet(isPresented: $showPump) {
            PumpSheet(post: post).environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            if let rank { rankBadge(rank) }
            Image(systemName: post.author.avatarSystemName)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40)
                .background(Theme.surfaceElevated, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(post.author.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(post.author.handle) · \(flag(post.author.countryCode))")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            CountdownRing(lifeFraction: lifeFraction, remaining: remaining)
        }
    }

    private var footer: some View {
        HStack {
            // Barre de boost : représentation visuelle du boost vivant.
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(boost > 0 ? Theme.gold : Theme.textSecondary)
                Text("\(post.pumps.count) pumps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            PumpButton(liveBoost: boost) { showPump = true }
        }
    }

    private func rankBadge(_ rank: Int) -> some View {
        Text("#\(rank)")
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(rank <= 3 ? .black : Theme.textPrimary)
            .frame(width: 34, height: 34)
            .background(rank <= 3 ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Theme.surfaceElevated),
                        in: Circle())
    }
}

/// Drapeau emoji à partir d'un code pays ISO-2.
func flag(_ code: String) -> String {
    let base: UInt32 = 0x1F1E6
    var s = ""
    for scalar in code.uppercased().unicodeScalars where scalar.value >= 65 && scalar.value <= 90 {
        if let u = Unicode.Scalar(base + scalar.value - 65) { s.unicodeScalars.append(u) }
    }
    return s.isEmpty ? code : s
}
