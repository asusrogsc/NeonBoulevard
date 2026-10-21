# Néon Boulevard (Godot 4.7)

Beat'em up 2.5D façon Streets of Rage, jouable seul, à deux ou avec un partenaire IA : deux héros (Jade et Bruno), deux stages (Boulevard Néon, Les Docks), des vagues d'ennemis et un boss.
Tout est généré par le code : les modèles 3D, les décors, les sons et la musique. Le projet ne contient aucun fichier image ou audio.

## Lancer le jeu
1. Ouvre Godot 4.7 (ou plus récent).
2. Dans le gestionnaire de projets, clique sur **Importer**, puis choisis le fichier `project.godot` de ce dossier.
3. Appuie sur **F5** (ou sur le bouton ▶ en haut à droite).

## Modes de jeu
À l'écran de choix, chaque héros peut être **Joueur**, **IA** ou **Absent** (← → pour choisir le héros, ↑ ↓ pour changer son rôle) :
- **Solo** : un héros joueur, l'autre absent.
- **Coop 2 joueurs** : les deux héros joueurs, sur le même écran.
- **Joueur + IA** : ton partenaire est contrôlé par l'ordinateur (il attaque, prend les ennemis à revers, esquive le boss, te laisse la nourriture si tu es plus blessé que lui).
- **Démo** : les deux héros en IA.

Chaque joueur a ses propres vies. La partie s'arrête quand tous les joueurs humains sont hors jeu.

## Commandes
| Action | Joueur 1 | Joueur 2 | Manette |
|---|---|---|---|
| Se déplacer | ZQSD | Flèches | Stick gauche / croix |
| Coup (3 coups enchaînés) | J ou X | Pavé num. 1 (ou `;`) | X / Carré |
| Saut (+ coup = coup de pied sauté) | K ou C | Pavé num. 2 (ou `:`) | A / Croix |
| Spécial (touche tout autour, coûte de la vie) | L ou V | Pavé num. 3 (ou `!`) | Y / Triangle |

En solo, le joueur peut utiliser les deux jeux de touches. En coop, la manette 1 va au joueur 1 et la manette 2 au joueur 2. Les touches `; : !` sont celles d'un clavier AZERTY (sur QWERTY : `, . /`).

| Autres | Touche |
|---|---|
| Chope | Avancer contre un ennemi, puis Coup = genou, direction opposée + Coup = projection |
| Valider | Entrée / Espace / Start |
| Pause | P ou Échap / Select |
| Son on/off | M |
| Plein écran | F11 |
| Qualité haute/rapide | F2 |

## Organisation
- `scripts/main.gd` : boucle de jeu, combats, IA des ennemis et du partenaire, zones, caméra, HUD
- `scripts/pose.gd` : les poses d'animation (angles des articulations)
- `scripts/rig.gd` : le modèle 3D articulé des personnages
- `scripts/stage.gd` : la construction des décors et de l'éclairage
- `scripts/sfx.gd` : les bruitages et la musique synthétisés
- `scripts/hud.gd` : la couche 2D

Pour régler la difficulté, modifie `HEROES` et `ETYPES` en haut de `main.gd` : points de vie, vitesse, dégâts, portée et délai entre les attaques. Les vagues d'ennemis se règlent dans `STAGES`.
