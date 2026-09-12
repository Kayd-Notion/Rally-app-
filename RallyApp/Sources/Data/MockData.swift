import Foundation

/// Données de démarrage pour l'aperçu : quelques utilisateurs, des posts à
/// différents âges, et des pumps échelonnés dans le temps pour qu'on voie
/// tout de suite un feed vivant et un classement crédible.
enum MockData {

    struct Seed {
        let currentUser: User
        let posts: [Post]
    }

    static func seed(now: Date = Date()) -> Seed {
        let me   = User(handle: "@toi", displayName: "Toi",
                        avatarSystemName: "person.crop.circle.fill", countryCode: "FR")
        let lea  = User(handle: "@lea", displayName: "Léa",
                        avatarSystemName: "sparkles", countryCode: "FR")
        let max  = User(handle: "@max", displayName: "Max",
                        avatarSystemName: "flame.fill", countryCode: "FR")
        let aya  = User(handle: "@aya", displayName: "Aya",
                        avatarSystemName: "bolt.fill", countryCode: "JP")
        let sam  = User(handle: "@sam", displayName: "Sam",
                        avatarSystemName: "star.fill", countryCode: "US")
        let noa  = User(handle: "@noa", displayName: "Noa",
                        avatarSystemName: "moon.stars.fill", countryCode: "US")

        func mins(_ m: Double) -> Date { now.addingTimeInterval(-m * 60) }

        var posts: [Post] = [
            Post(author: lea, text: "Premier café, premier pump. On lance la journée ☕️🚀",
                 createdAt: mins(4),
                 pumps: [Pump(amount: 3.5, date: mins(2), pumperID: max.id),
                         Pump(amount: 5.0, date: mins(1), pumperID: sam.id)]),

            Post(author: max, text: "Ce coucher de soleil mérite d'être sauvé avant qu'il disparaisse 🌇",
                 createdAt: mins(9),
                 pumps: [Pump(amount: 8.0, date: mins(6), pumperID: lea.id),
                         Pump(amount: 4.0, date: mins(3), pumperID: aya.id),
                         Pump(amount: 6.5, date: mins(1), pumperID: noa.id)]),

            Post(author: aya, text: "東京は今夜も眠らない — Tokyo ne dort jamais.",
                 createdAt: mins(12),
                 pumps: [Pump(amount: 12.0, date: mins(5), pumperID: sam.id)]),

            Post(author: sam, text: "gm. today we pump 📈",
                 createdAt: mins(2)),

            Post(author: noa, text: "Hot take: ephemeral > permanent. Fight me.",
                 createdAt: mins(18),
                 pumps: [Pump(amount: 2.0, date: mins(15), pumperID: max.id)]),

            // Un post presque expiré, pour montrer l'urgence du compte à rebours.
            Post(author: lea, text: "Il me reste quelques minutes… quelqu'un me sauve ? 🙏",
                 createdAt: mins(27),
                 pumps: [Pump(amount: 1.0, date: mins(20), pumperID: sam.id)]),
        ]

        // Un post tout frais de "toi" pour peupler le profil.
        posts.append(Post(author: me, text: "Je teste Rally. C'est quoi ce truc de fou 👀",
                          createdAt: mins(1)))

        return Seed(currentUser: me, posts: posts)
    }
}
