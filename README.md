# Rally — aperçu de l'app iOS (V1)

Réseau social **éphémère** où l'on **pump** des posts en payant en crypto pour
les faire monter en visibilité — avec des **classements du moment**, mondial et
par pays.

> ⚠️ Nom pas encore tranché (Rally / Bump / Pumpr…). Ici c'est « Rally » par défaut.

Ce dossier `RallyApp/` est un **aperçu d'interface en SwiftUI** : une maquette
**interactive** avec des **données simulées**. Aucun réseau, aucun vrai paiement.
C'est volontaire — on valide d'abord l'expérience et les formules, on branche du
vrai argent seulement quand tout est solide et testé.

---

## Ce que tu peux déjà voir bouger

- **Feed éphémère** : chaque post a un anneau de compte à rebours qui se remplit
  en direct ; quand il atteint zéro, le post disparaît du feed.
- **Pump** : bouton signature → feuille de paiement qui montre **tout avant de
  valider** (montant, où va l'argent, effet sur la visibilité **et** sur la durée
  de vie).
- **Deux effets du pump** :
  1. **Visibilité** : le post remonte dans le feed, puis l'effet **s'estompe**
     (décroissance exponentielle).
  2. **Vie prolongée** : chaque pump **prolonge le compte à rebours** — la piste
     « sauver un post » plutôt que juste le booster.
- **Classements du moment** : Monde + Pays, sur une **fenêtre glissante** (pas de
  « tous les temps », puisque les posts meurent) → urgence / FOMO.
- **Wallet simulé** : solde crypto factice pour tester les pumps (bouton
  « Recharger » dans le profil).

---

## Lancer l'aperçu

Il faut un Mac avec Xcode (le SwiftUI ne se compile que là).

**Option A — XcodeGen (le plus simple)**
```bash
brew install xcodegen        # une fois
cd RallyApp
xcodegen generate            # crée RallyApp.xcodeproj
open RallyApp.xcodeproj       # puis ⌘R sur un simulateur iPhone
```

**Option B — à la main dans Xcode**
1. Xcode → *File ▸ New ▸ Project… ▸ iOS App*, SwiftUI, nom `RallyApp`.
2. Supprime le fichier `ContentView.swift` généré.
3. Glisse le dossier `RallyApp/Sources/` dans le projet (« Copy if needed »).
4. ⌘R.

**Tests** : ⌘U dans Xcode (voir `Tests/BoostEngineTests.swift`).

---

## Architecture (et pourquoi)

```
Sources/
  App/        → point d'entrée + barre d'onglets
  Models/     → Post, User, Pump (structures de données pures)
  Engine/     → RallyConfig (tous les réglages) + BoostEngine (toute la logique)
  Data/       → RallyStore (état de l'app, horloge live) + MockData
  Views/      → Feed, Pump, Rankings, Profile, Components
Tests/        → tests du moteur
```

Le principe clé : **toute la logique sensible est dans `Engine/`, séparée de
l'UI**. `BoostEngine` ne fait que des maths pures (pas de réseau, pas d'argent),
donc c'est **testable** et c'est là qu'on mettra le plus de garde-fous quand on
passera aux vrais paiements. `RallyConfig` regroupe **tous les paramètres pas
encore tranchés** en un seul endroit.

Autre choix important : on **ne stocke jamais** « le boost actuel » ou « le temps
restant » comme des valeurs figées. On les **recalcule à la volée** à partir de
`createdAt` et de la liste des `pumps`. Une seule source de vérité, pas de
désynchronisation possible.

---

## Les paramètres V1 (tout dans `Engine/RallyConfig.swift`)

Valeurs de **démo** (durées courtes pour voir les choses bouger). À ajuster
ensemble avant un vrai lancement.

| Paramètre                | Valeur démo | Rôle |
|--------------------------|-------------|------|
| `baseLifetime`           | 30 min      | vie d'un post neuf (prod : ~24 h) |
| `lifetimeGainPerUnit`    | 4 min/unité | prolongation gagnée par pump |
| `maxLifetime`            | 6 h         | plafond anti-immortalité |
| `boostHalfLife`          | 10 min      | demi-vie de l'effet visibilité |
| `rankingWindow`          | 1 h         | fenêtre du classement du moment |
| `creatorShare` / `platformShare` | 70 % / 30 % | partage du paiement |

### Les formules, en clair
- **Boost vivant d'un pump** : `montant × (1/2)^(âge / demi-vie)` → l'effet fond
  de moitié à chaque demi-vie.
- **Tri du feed** : `fraîcheur + boost_vivant × poids` → payer achète de la
  visibilité, sans écraser totalement le contenu récent.
- **Score de classement** : somme des pumps reçus **dans la fenêtre** seulement.
- **Split** : `créateur = montant × 0,70`, `plateforme = montant × 0,30`
  (invariant testé : la somme fait toujours le total).

---

## Points encore à trancher (mes recommandations)

1. **Durée de vie des posts** — commencer court (12–24 h) pour marquer
   l'éphémère ; la prolongation par pump donne le levier émotionnel.
2. **Fenêtre du classement** — court (1–6 h) = plus de FOMO, mais plus volatil.
   À tester ; c'est un simple réglage ici.
3. **Formule du score** — pour la V1, garder **linéaire et lisible** (somme des
   montants). Éviter tout ce qui ressemble à un rendement financier (→ risque
   légal, cf. ci-dessous).
4. **« Pays » d'un utilisateur (vie privée)** — dans l'aperçu on prend le pays
   de l'auteur (`countryCode`). En vrai : ne **pas** géolocaliser en continu.
   Préférer un pays **déclaré** par l'utilisateur (ou déduit une seule fois,
   grossièrement, et modifiable), stocké au niveau **pays** uniquement — jamais
   de coordonnées fines.

---

## Volontairement PAS dans la V1

La couche **spéculative (bonding curve)** où les early pumpers gagnent quand
d'autres pump après eux est **mise de côté** : complexité technique, vrai risque
légal (ça ressemble à un instrument financier), et risque de pump-and-dump
(cf. pump.fun / friend.tech). La V1 reste un **boost de visibilité**, pas un
investissement.

---

## Prochaines étapes possibles

- Écran de détail d'un post + liste des pumpers.
- Animation « le post disparaît » quand le compte à rebours atteint zéro.
- Notion de pumper **une personne** (pas seulement un post).
- Puis seulement : brancher un vrai wallet / paiement — derrière une batterie de
  tests, en argent de test d'abord.
