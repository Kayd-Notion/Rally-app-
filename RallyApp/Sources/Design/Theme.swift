import SwiftUI

/// Le "design system" minimal de l'aperçu : couleurs et styles réutilisables.
/// Centralisé pour qu'on change l'ambiance d'un seul endroit.
enum Theme {

    // Fond sombre, accents vifs — ambiance "énergie / hype".
    static let background      = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let surface         = Color(red: 0.11, green: 0.11, blue: 0.16)
    static let surfaceElevated = Color(red: 0.16, green: 0.16, blue: 0.22)

    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.6)

    // Vert électrique = le pump / la montée.
    static let accent = Color(red: 0.20, green: 1.0, blue: 0.55)
    // Rose/orange = l'urgence, le temps qui file.
    static let urgent = Color(red: 1.0, green: 0.35, blue: 0.45)
    static let gold   = Color(red: 1.0, green: 0.80, blue: 0.30)

    static let pumpGradient = LinearGradient(
        colors: [Color(red: 0.20, green: 1.0, blue: 0.55),
                 Color(red: 0.0, green: 0.75, blue: 0.95)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// Petit formateur pour afficher les montants crypto de façon homogène.
enum Format {
    static func crypto(_ amount: Double) -> String {
        String(format: "%@ %.2f", RallyConfig.currencySymbol, amount)
    }

    /// Compte à rebours lisible : "12:34" ou "1 h 05".
    static func countdown(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d h %02d", h, m) }
        return String(format: "%02d:%02d", m, s)
    }
}
