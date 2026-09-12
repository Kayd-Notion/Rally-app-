import SwiftUI

/// Anneau de compte à rebours affiché sur chaque post.
/// Il se remplit à mesure que la vie du post se consume, et vire au rouge
/// quand le temps devient critique — l'urgence de l'éphémère, visible d'un coup d'œil.
struct CountdownRing: View {
    let lifeFraction: Double        // 0 = neuf, 1 = expiré
    let remaining: TimeInterval

    private var isCritical: Bool { lifeFraction > 0.8 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceElevated, lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(1 - lifeFraction))
                .stroke(isCritical ? Theme.urgent : Theme.accent,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: lifeFraction)

            Text(Format.countdown(remaining))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(isCritical ? Theme.urgent : Theme.textSecondary)
        }
        .frame(width: 46, height: 46)
    }
}
