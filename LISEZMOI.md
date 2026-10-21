# Néon Boulevard (Godot 4)

Beat'em up 2.5D façon Streets of Rage : deux héros (Jade et Bruno), deux stages (Boulevard Néon, Les Docks), des vagues d'ennemis et un boss.
Tout est généré par le code : les modèles 3D, les décors, les sons et la musique. Le projet ne contient aucun fichier image ou audio.

## Lancer le jeu
1. Ouvre Godot 4 (4.3 ou plus récent).
2. Dans le gestionnaire de projets, clique sur **Importer**, puis choisis le fichier `project.godot` de ce dossier.
3. Appuie sur **F5** (ou sur le bouton ▶ en haut à droite).

## Commandes
| Action | Clavier | Manette |
|---|---|---|
| Se déplacer | Flèches ou ZQSD | Stick gauche / croix |
| Coup (3 coups enchaînés) | J ou X | X / Carré |
| Saut (+ coup = coup de pied sauté) | K ou C | A / Croix |
| Spécial (touche tout autour, coûte de la vie) | L ou V | Y / Triangle |
| Chope | Avancer contre un ennemi, puis Coup = genou, direction opposée + Coup = projection | |
| Valider | Entrée / Espace | Start |
| Pause | P ou Échap | Select |
| Son on/off | M | |
| Plein écran | F11 | |
| Qualité haute/rapide | F2 | |

## Organisation
- `scripts/main.gd` : boucle de jeu, combats, IA des ennemis, zones, caméra, HUD
- `scripts/pose.gd` : les poses d'animation (angles des articulations)
- `scripts/rig.gd` : le modèle 3D articulé des personnages
- `scripts/stage.gd` : la construction des décors et de l'éclairage
- `scripts/sfx.gd` : les bruitages et la musique synthétisés
- `scripts/hud.gd` : la couche 2D

Pour régler la difficulté, modifie `HEROES` et `ETYPES` en haut de `main.gd` : points de vie, vitesse, dégâts, portée et délai entre les attaques. Les vagues d'ennemis se règlent dans `STAGES`.
