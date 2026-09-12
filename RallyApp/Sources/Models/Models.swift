import Foundation

/// Un utilisateur (créateur ou pumper).
struct User: Identifiable, Hashable {
    let id: UUID
    var handle: String          // ex. "@lea"
    var displayName: String
    var avatarSystemName: String // SF Symbol, en attendant de vraies images
    var countryCode: String      // ISO-2, ex. "FR" — voir la note vie privée dans le README

    init(id: UUID = UUID(), handle: String, displayName: String,
         avatarSystemName: String, countryCode: String) {
        self.id = id
        self.handle = handle
        self.displayName = displayName
        self.avatarSystemName = avatarSystemName
        self.countryCode = countryCode
    }
}

/// Un pump = un paiement crypto pour booster un post.
/// On garde la trace de *quand* et *combien*, car le moteur en a besoin pour
/// calculer la décroissance du boost et le classement du moment.
struct Pump: Identifiable, Hashable {
    let id: UUID
    var amount: Double          // montant en crypto
    var date: Date
    var pumperID: UUID

    init(id: UUID = UUID(), amount: Double, date: Date, pumperID: UUID) {
        self.id = id
        self.amount = amount
        self.date = date
        self.pumperID = pumperID
    }
}

/// Un post éphémère.
///
/// On ne stocke PAS "le boost actuel" ni "le temps restant" comme des champs
/// figés : ce sont des valeurs qui dépendent de l'heure qu'il est. On les
/// calcule à la volée dans BoostEngine à partir de `createdAt` et de `pumps`.
/// Comme ça il n'y a qu'une seule source de vérité.
struct Post: Identifiable, Hashable {
    let id: UUID
    var author: User
    var text: String
    var createdAt: Date
    var pumps: [Pump]

    init(id: UUID = UUID(), author: User, text: String,
         createdAt: Date, pumps: [Pump] = []) {
        self.id = id
        self.author = author
        self.text = text
        self.createdAt = createdAt
        self.pumps = pumps
    }

    /// Total brut pumpé sur ce post (toutes époques confondues), utile pour
    /// l'affichage "ce post a reçu X au total".
    var totalPumped: Double {
        pumps.reduce(0) { $0 + $1.amount }
    }
}
