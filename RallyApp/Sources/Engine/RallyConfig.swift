import Foundation

/// Paramètres réglables de la V1.
///
/// ⚠️  Tout ce qui est "pas encore tranché" dans ton concept vit ICI, en un seul
///     endroit, pour qu'on puisse ajuster sans fouiller dans le reste du code :
///       - la durée de vie des posts
///       - la fenêtre du classement "du moment"
///       - la formule / les constantes du score de boost
///       - le partage des revenus créateur / plateforme
///
/// Ce sont des valeurs de départ, pensées pour que la démo soit lisible à l'œil
/// (comptes à rebours en minutes plutôt qu'en heures, boost qui décroît vite).
/// Pour un vrai lancement on rallongera les durées.
enum RallyConfig {

    // MARK: - Durée de vie des posts (éphémère)

    /// Durée de vie de base d'un post à sa création (avant tout pump).
    /// Réglage démo : 30 min pour voir les choses bouger. En prod : plutôt 24 h.
    static let baseLifetime: TimeInterval = 30 * 60

    /// Piste "sauver un post" : chaque pump prolonge la durée de vie.
    /// On ajoute `lifetimeGainPerUnit` secondes par unité de crypto pumpée…
    static let lifetimeGainPerUnit: TimeInterval = 4 * 60

    /// …mais on plafonne la vie totale, sinon un post populaire devient immortel
    /// et on perd tout l'intérêt de l'éphémère.
    static let maxLifetime: TimeInterval = 6 * 60 * 60

    // MARK: - Boost / visibilité

    /// Demi-vie du boost : au bout de ce délai, l'effet d'un pump donné a fondu
    /// de moitié. C'est ce qui fait que "l'effet s'estompe avec le temps".
    static let boostHalfLife: TimeInterval = 10 * 60

    /// Poids du boost dans le tri du feed, relatif à la fraîcheur du post.
    /// Plus c'est haut, plus payer "achète" de la visibilité par rapport au
    /// simple fait d'être récent.
    static let boostFeedWeight: Double = 1.0

    // MARK: - Classement "du moment"

    /// Fenêtre du classement : on ne compte que les pumps reçus dans ce laps de
    /// temps. Comme les posts disparaissent, un classement "de tous les temps"
    /// n'a pas de sens → on crée de l'urgence avec une fenêtre courte.
    static let rankingWindow: TimeInterval = 60 * 60

    // MARK: - Économie du paiement

    /// Part reversée au créateur du post pumpé.
    static let creatorShare: Double = 0.70
    /// Part gardée par la plateforme.
    static let platformShare: Double = 0.30

    /// Devise crypto affichée dans l'aperçu (purement cosmétique ici).
    static let currencySymbol = "◎"   // clin d'œil Solana, à trancher
    static let currencyCode = "RLY"
}
