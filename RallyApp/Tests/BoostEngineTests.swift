import XCTest
@testable import RallyApp

/// Tests du moteur. On ne branchera jamais de vrai paiement sans que cette
/// logique soit verte. C'est le filet de sécurité "argent réel" dès le départ.
final class BoostEngineTests: XCTestCase {

    private func user() -> User {
        User(handle: "@u", displayName: "U", avatarSystemName: "person", countryCode: "FR")
    }

    // MARK: - Partage du paiement

    func testSplitSommeExacte() {
        let s = BoostEngine.split(amount: 10)
        XCTAssertEqual(s.toCreator, 7, accuracy: 1e-9)
        XCTAssertEqual(s.toPlatform, 3, accuracy: 1e-9)
        // Invariant fondamental : on ne perd ni ne crée d'argent.
        XCTAssertEqual(s.toCreator + s.toPlatform, s.total, accuracy: 1e-9)
    }

    func testSplitProportionnel() {
        for amount in [0.5, 1, 3.33, 42, 1000.0] {
            let s = BoostEngine.split(amount: amount)
            XCTAssertEqual(s.toCreator + s.toPlatform, amount, accuracy: 1e-9,
                           "Le split doit toujours sommer au total (\(amount)).")
        }
    }

    // MARK: - Décroissance du boost

    func testBoostDecroitDeMoitieApresUneDemiVie() {
        let now = Date()
        let old = now.addingTimeInterval(-RallyConfig.boostHalfLife)
        let pump = Pump(amount: 10, date: old, pumperID: UUID())
        // Après exactement une demi-vie, il reste la moitié.
        XCTAssertEqual(BoostEngine.liveValue(of: pump, at: now), 5, accuracy: 1e-6)
    }

    func testBoostFraisVautSonMontant() {
        let now = Date()
        let pump = Pump(amount: 8, date: now, pumperID: UUID())
        XCTAssertEqual(BoostEngine.liveValue(of: pump, at: now), 8, accuracy: 1e-9)
    }

    // MARK: - Durée de vie / "sauver le post"

    func testPumpProlongeLaVie() {
        let now = Date()
        let sans = Post(author: user(), text: "x", createdAt: now)
        let avec = Post(author: user(), text: "x", createdAt: now,
                        pumps: [Pump(amount: 5, date: now, pumperID: UUID())])
        XCTAssertGreaterThan(BoostEngine.totalLifetime(of: avec),
                             BoostEngine.totalLifetime(of: sans))
    }

    func testViePlafonnee() {
        let now = Date()
        // Un pump énorme ne doit pas rendre le post immortel.
        let post = Post(author: user(), text: "x", createdAt: now,
                        pumps: [Pump(amount: 1_000_000, date: now, pumperID: UUID())])
        XCTAssertEqual(BoostEngine.totalLifetime(of: post), RallyConfig.maxLifetime, accuracy: 1e-6)
    }

    func testPostExpire() {
        let created = Date().addingTimeInterval(-RallyConfig.baseLifetime - 60)
        let post = Post(author: user(), text: "x", createdAt: created)
        XCTAssertFalse(BoostEngine.isAlive(post, at: Date()))
        XCTAssertEqual(BoostEngine.timeRemaining(of: post, at: Date()), 0, accuracy: 1e-6)
    }

    // MARK: - Classement du moment

    func testClassementIgnoreLesPumpsHorsFenetre() {
        let now = Date()
        let vieux = now.addingTimeInterval(-RallyConfig.rankingWindow - 60)
        let post = Post(author: user(), text: "x", createdAt: vieux,
                        pumps: [Pump(amount: 100, date: vieux, pumperID: UUID())])
        // Pump trop vieux → ne compte pas dans le classement du moment.
        XCTAssertEqual(BoostEngine.momentumScore(of: post, at: now), 0, accuracy: 1e-9)
    }

    func testClassementCompteLesPumpsRecents() {
        let now = Date()
        let post = Post(author: user(), text: "x", createdAt: now,
                        pumps: [Pump(amount: 4, date: now, pumperID: UUID()),
                                Pump(amount: 6, date: now, pumperID: UUID())])
        XCTAssertEqual(BoostEngine.momentumScore(of: post, at: now), 10, accuracy: 1e-9)
    }
}
