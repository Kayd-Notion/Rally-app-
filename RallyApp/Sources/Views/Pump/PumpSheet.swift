import SwiftUI

/// La feuille de pump : c'est ici que "l'argent" se manipule, donc c'est
/// l'écran qu'on soigne le plus. On montre TOUT avant de valider :
///   - où va l'argent (créateur / plateforme),
///   - de combien on booste la visibilité,
///   - de combien on prolonge la vie du post ("sauver le post").
struct PumpSheet: View {
    @EnvironmentObject var store: RallyStore
    @Environment(\.dismiss) var dismiss
    let post: Post

    @State private var amount: Double = 5
    @State private var confirmed = false

    private let presets: [Double] = [1, 5, 10, 25]
    private var split: BoostEngine.PaymentSplit { BoostEngine.split(amount: amount) }

    /// Combien de temps de vie ce pump ajoute (avant plafond).
    private var lifeGain: TimeInterval { amount * RallyConfig.lifetimeGainPerUnit }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if confirmed { successView } else { pumpForm }
            }
            .background(Theme.background)
            .navigationTitle(confirmed ? "" : "Pumper ce post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(confirmed ? "Fermer" : "Annuler") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .tint(Theme.accent)
    }

    // MARK: - Formulaire

    private var pumpForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                targetCard
                amountSelector
                effectPreview
                splitBreakdown
                Spacer(minLength: 8)
                confirmButton
            }
            .padding(20)
        }
    }

    private var targetCard: some View {
        HStack(spacing: 12) {
            Image(systemName: post.author.avatarSystemName)
                .font(.system(size: 22)).foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Theme.surfaceElevated, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(post.author.displayName).font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(post.text).font(.system(size: 13)).lineLimit(2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var amountSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MONTANT").font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textSecondary)

            Text(Format.crypto(amount))
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.accent)

            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { value in
                    Button {
                        amount = value
                    } label: {
                        Text(Format.crypto(value))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(amount == value ? .black : Theme.textPrimary)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(amount == value ? AnyShapeStyle(Theme.accent)
                                        : AnyShapeStyle(Theme.surfaceElevated),
                                        in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // On borne le haut au solde, mais jamais en dessous du minimum,
            // sinon la plage du Slider serait invalide (0.5...0.3 → crash).
            Slider(value: $amount,
                   in: 0.5...max(0.5, min(50, store.walletBalance)),
                   step: 0.5)
                .tint(Theme.accent)
            Text("Solde : \(Format.crypto(store.walletBalance))")
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
    }

    /// Aperçu des DEUX effets du pump.
    private var effectPreview: some View {
        HStack(spacing: 12) {
            effectTile(icon: "chart.line.uptrend.xyaxis",
                       title: "Visibilité",
                       value: "+\(Format.crypto(amount))",
                       caption: "s'estompe avec le temps",
                       color: Theme.accent)
            effectTile(icon: "clock.arrow.circlepath",
                       title: "Vie prolongée",
                       value: "+\(Format.countdown(lifeGain))",
                       caption: "tu sauves le post",
                       color: Theme.gold)
        }
    }

    private func effectTile(icon: String, title: String, value: String,
                            caption: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(title).font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(caption).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    /// La transparence sur l'argent : qui reçoit quoi.
    private var splitBreakdown: some View {
        VStack(spacing: 10) {
            splitRow(label: "Au créateur (\(Int(RallyConfig.creatorShare * 100)) %)",
                     value: split.toCreator, color: Theme.accent)
            splitRow(label: "Plateforme (\(Int(RallyConfig.platformShare * 100)) %)",
                     value: split.toPlatform, color: Theme.textSecondary)
            Divider().overlay(Theme.surfaceElevated)
            splitRow(label: "Total", value: split.total, color: Theme.textPrimary, bold: true)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func splitRow(label: String, value: Double, color: Color,
                          bold: Bool = false) -> some View {
        HStack {
            Text(label).font(.system(size: 14, weight: bold ? .bold : .regular))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(Format.crypto(value))
                .font(.system(size: 14, weight: bold ? .heavy : .semibold, design: .rounded))
                .foregroundStyle(color)
        }
    }

    private var confirmButton: some View {
        Button {
            guard store.pump(post, amount: amount) != nil else { return }
            withAnimation(.spring) { confirmed = true }
        } label: {
            Text("Pumper \(Format.crypto(amount))")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Theme.pumpGradient, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(amount > store.walletBalance)
        .opacity(amount > store.walletBalance ? 0.5 : 1)
    }

    // MARK: - Confirmation

    private var successView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64)).foregroundStyle(Theme.accent)
            Text("Post pumpé 🚀").font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
            Text("Tu as boosté \(post.author.displayName) et prolongé la vie du post.")
                .font(.system(size: 15)).multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
