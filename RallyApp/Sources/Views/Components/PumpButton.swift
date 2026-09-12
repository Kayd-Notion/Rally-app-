import SwiftUI

/// Le bouton signature de l'app. Affiche le boost vivant du post et déclenche
/// la feuille de pump. Un petit pulse quand on appuie, pour le côté satisfaisant.
struct PumpButton: View {
    let liveBoost: Double
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { pulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { pulse = false }
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .bold))
                Text(liveBoost > 0 ? Format.crypto(liveBoost) : "Pump")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.pumpGradient, in: Capsule())
            .scaleEffect(pulse ? 1.15 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
