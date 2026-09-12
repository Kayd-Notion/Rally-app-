import Foundation
import Combine

/// Source de données de l'aperçu. Pas de réseau, pas de vrai paiement :
/// tout est en mémoire. C'est volontaire — on valide l'expérience et les
/// formules AVANT de brancher quoi que ce soit qui touche à de l'argent réel.
///
/// `now` est une horloge qui avance chaque seconde. Toutes les vues observent
/// ce store, donc les comptes à rebours et les boosts se recalculent en direct.
@MainActor
final class RallyStore: ObservableObject {

    @Published private(set) var posts: [Post]
    @Published private(set) var now: Date = Date()

    /// Solde crypto simulé de l'utilisateur courant (pour la démo du pump).
    @Published private(set) var walletBalance: Double = 50

    let currentUser: User
    private var timer: AnyCancellable?

    init() {
        let seed = MockData.seed()
        self.currentUser = seed.currentUser
        self.posts = seed.posts
        startClock()
    }

    private func startClock() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in self?.now = date }
    }

    // MARK: - Feed

    /// Posts encore en vie, triés par score de feed (fraîcheur + boost payé).
    var liveFeed: [Post] {
        posts
            .filter { BoostEngine.isAlive($0, at: now) }
            .sorted { BoostEngine.feedScore(of: $0, at: now)
                    > BoostEngine.feedScore(of: $1, at: now) }
    }

    // MARK: - Classements du moment

    /// Classement mondial : tous pays confondus.
    func globalRanking() -> [Post] {
        rank(posts.filter { BoostEngine.isAlive($0, at: now) })
    }

    /// Classement par pays : on filtre sur le pays de l'AUTEUR du post.
    /// (Voir README pour la question vie privée sur "le pays d'un utilisateur".)
    func countryRanking(_ countryCode: String) -> [Post] {
        rank(posts.filter {
            BoostEngine.isAlive($0, at: now) && $0.author.countryCode == countryCode
        })
    }

    private func rank(_ input: [Post]) -> [Post] {
        input
            .filter { BoostEngine.momentumScore(of: $0, at: now) > 0 }
            .sorted { BoostEngine.momentumScore(of: $0, at: now)
                    > BoostEngine.momentumScore(of: $1, at: now) }
    }

    /// Pays présents dans le feed, pour proposer un sélecteur.
    var availableCountries: [String] {
        Array(Set(posts.map { $0.author.countryCode })).sorted()
    }

    // MARK: - Actions

    /// Pumper un post. Dans l'aperçu on débite juste le solde simulé et on
    /// ajoute un Pump horodaté. En prod, cette méthode déclenchera le vrai
    /// paiement crypto — et sera la fonction la plus testée de l'app.
    /// Renvoie le détail du partage pour affichage/confirmation.
    @discardableResult
    func pump(_ post: Post, amount: Double) -> BoostEngine.PaymentSplit? {
        guard amount > 0, amount <= walletBalance,
              let idx = posts.firstIndex(where: { $0.id == post.id }) else { return nil }

        walletBalance -= amount
        let pump = Pump(amount: amount, date: now, pumperID: currentUser.id)
        posts[idx].pumps.append(pump)
        return BoostEngine.split(amount: amount)
    }

    /// Publier un nouveau post (démo).
    func createPost(text: String) {
        let post = Post(author: currentUser, text: text, createdAt: now)
        posts.insert(post, at: 0)
    }

    /// Recharger le solde simulé (bouton démo).
    func topUp(_ amount: Double = 25) { walletBalance += amount }
}
