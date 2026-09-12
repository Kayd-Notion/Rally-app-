import Foundation

/// Le moteur : toute la logique "économique" et temporelle du pump vit ici,
/// séparée de l'interface. C'est le fichier le plus important à comprendre.
///
/// Aucune de ces fonctions ne touche au réseau ni à l'argent réel : ce sont des
/// maths pures et testables. Quand on branchera de vrais paiements, on validera
/// d'abord ces formules avec des tests avant de manipuler le moindre centime.
enum BoostEngine {

    // MARK: - Décroissance d'un pump

    /// Valeur "vivante" d'un pump à un instant donné.
    ///
    /// On part du montant payé et on le fait décroître exponentiellement :
    /// à chaque `boostHalfLife` écoulée, il ne reste que la moitié de l'effet.
    ///     valeur = montant · (1/2)^(âge / demi-vie)
    ///
    /// C'est ça, "l'effet du boost s'estompe avec le temps".
    static func liveValue(of pump: Pump, at now: Date) -> Double {
        let age = now.timeIntervalSince(pump.date)
        guard age > 0 else { return pump.amount }
        let halfLives = age / RallyConfig.boostHalfLife
        return pump.amount * pow(0.5, halfLives)
    }

    /// Boost total et vivant d'un post = somme des pumps décroissants.
    /// Un post beaucoup pumpé il y a longtemps peut donc être dépassé par un
    /// post fraîchement pumpé : c'est voulu, ça garde le feed vivant.
    static func liveBoost(of post: Post, at now: Date) -> Double {
        post.pumps.reduce(0) { $0 + liveValue(of: $1, at: now) }
    }

    // MARK: - Durée de vie (éphémère + "sauver un post")

    /// Durée de vie totale d'un post : base + bonus gagné via les pumps,
    /// plafonnée pour que rien ne devienne immortel.
    ///
    /// Note : ici on prend le total brut pumpé (pas la version décroissante) —
    /// prolonger la vie est un effet "acquis" : une fois que tu as sauvé le
    /// post, il reste sauvé, même quand le boost de visibilité, lui, a fondu.
    static func totalLifetime(of post: Post) -> TimeInterval {
        let bonus = post.totalPumped * RallyConfig.lifetimeGainPerUnit
        return min(RallyConfig.baseLifetime + bonus, RallyConfig.maxLifetime)
    }

    /// Date d'expiration du post.
    static func expiryDate(of post: Post) -> Date {
        post.createdAt.addingTimeInterval(totalLifetime(of: post))
    }

    /// Temps restant avant disparition (0 si déjà expiré).
    static func timeRemaining(of post: Post, at now: Date) -> TimeInterval {
        max(0, expiryDate(of: post).timeIntervalSince(now))
    }

    /// Le post est-il encore en vie ?
    static func isAlive(_ post: Post, at now: Date) -> Bool {
        timeRemaining(of: post, at: now) > 0
    }

    /// Fraction de vie déjà consommée, de 0 (neuf) à 1 (expiré).
    /// Sert à l'anneau de compte à rebours dans l'UI.
    static func lifeFraction(of post: Post, at now: Date) -> Double {
        let total = totalLifetime(of: post)
        guard total > 0 else { return 1 }
        let elapsed = now.timeIntervalSince(post.createdAt)
        return min(1, max(0, elapsed / total))
    }

    // MARK: - Tri du feed

    /// Score de tri du feed : mélange fraîcheur + boost payé.
    ///
    /// On combine deux forces :
    ///   - un post récent remonte tout seul (fraîcheur),
    ///   - le boost payé, pondéré par `boostFeedWeight`, pousse par-dessus.
    /// Payer fait donc monter en visibilité, sans pour autant écraser
    /// totalement le contenu récent non pumpé.
    static func feedScore(of post: Post, at now: Date) -> Double {
        let freshness = 1.0 - lifeFraction(of: post, at: now)   // 1 = tout neuf
        let boost = liveBoost(of: post, at: now)
        return freshness + boost * RallyConfig.boostFeedWeight
    }

    // MARK: - Classement "du moment"

    /// Score de classement : uniquement les pumps reçus dans la fenêtre
    /// `rankingWindow`. Comme les posts disparaissent, on ne classe que
    /// "l'instant présent" → urgence et FOMO.
    static func momentumScore(of post: Post, at now: Date) -> Double {
        let cutoff = now.addingTimeInterval(-RallyConfig.rankingWindow)
        return post.pumps
            .filter { $0.date >= cutoff }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Partage du paiement (le point sensible)

    /// Résultat d'un pump : combien va au créateur, combien à la plateforme.
    /// Renvoyé explicitement pour qu'on puisse l'AFFICHER à l'utilisateur avant
    /// de payer, et le tester. On ne bougera pas d'argent réel sans que ce
    /// calcul soit couvert par des tests.
    struct PaymentSplit {
        let total: Double
        let toCreator: Double
        let toPlatform: Double
    }

    static func split(amount: Double) -> PaymentSplit {
        let creator = amount * RallyConfig.creatorShare
        let platform = amount * RallyConfig.platformShare
        return PaymentSplit(total: amount, toCreator: creator, toPlatform: platform)
    }
}
