# Néon Boulevard (Godot 4.7)

Beat'em up 2.5D façon Streets of Rage, jouable seul, à deux ou avec un partenaire IA : deux héros (Jade et Bruno), trois stages (Boulevard Néon, Les Docks, Le Métro), des vagues d'ennemis et deux boss.
Tout est généré par le code : les modèles 3D, les décors, les sons et la musique. Le projet ne contient aucun fichier image ou audio.

## Lancer le jeu
1. Ouvre Godot 4.7 (ou plus récent).
2. Dans le gestionnaire de projets, clique sur **Importer**, puis choisis le fichier `project.godot` de ce dossier.
3. Appuie sur **F5** (ou sur le bouton ▶ en haut à droite).

## Contenu
- **Stages** : Boulevard Néon (pluie de nuit), Les Docks (crépuscule), Le Métro (quai et rame à l'arrêt). Chaque stage a sa musique, et le boss a la sienne.
- **Ennemis** : Punk, Rôdeur (ruée), Costaud (blindé pendant ses attaques), Lanceuse (garde ses distances et lance des couteaux, on peut les éviter en changeant de ligne ou en sautant).
- **Boss** : Le Contremaître (charge, piétinement) et Vipère (ruée rapide, éventail de trois couteaux). Quand un boss tombe, ses renforts tombent avec lui.
- **Armes** : tuyau (lent, longue portée, puissant) et couteau (rapide). On les trouve dans les caisses et poubelles, on les ramasse en marchant dessus. Elles s'usent et se cassent, et on les lâche si on est mis au sol.
- **Combos** : le compteur de coups s'affiche à côté de la barre de vie. À partir de 5 coups enchaînés, un bonus de points est donné.
- **Coup final** : le KO qui termine un stage déclenche un ralenti avec un flash.
- **Passants** : des habitants se baladent dans les stages et sur l'écran titre. Les ennemis les ignorent. Si on les frappe, ils sursautent et s'enfuient en courant (ça ne rapporte rien).

## Graphismes
Quatre niveaux de qualité (F2, sauvegardés) :
- **Bas** : sans ombres ni effets, image 3D calculée à 77 % puis agrandie (FSR). Pour les petites machines.
- **Moyen** : ombres, halo des néons, anticrénelage FXAA, vignettage, éclaboussures de pluie.
- **Haut** (par défaut) : + brouillard volumétrique avec faisceaux sous les lampadaires, reflets sur le sol mouillé (SSR), occlusion ambiante (SSAO), flou du décor lointain, grain et légère aberration chromatique, anticrénelage MSAA 2x + SMAA.
- **Ultra** : + éclairage indirect (SSIL), MSAA 4x, ombres plus fines, plus de pluie, gouttes sur l'objectif sous la pluie.

Toujours actifs : enseignes qui grésillent, flaques qui ondulent sous la pluie, lumière de contour sur les personnages, étalonnage des couleurs. F3 ajoute un filtre écran cathodique (lignes, grille RVB, bords bombés).

## Modes de jeu
À l'écran de choix, chaque héros peut être **Joueur**, **IA** ou **Absent** (← → pour choisir le héros, ↑ ↓ pour changer son rôle ; ← → ne fait que déplacer le curseur) :
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
| Niveau de qualité (Bas / Moyen / Haut / Ultra) | F2 |
| Écran CRT rétro | F3 |

## Organisation
- `scripts/main.gd` : boucle de jeu, combats, IA des ennemis et du partenaire, zones, caméra, HUD
- `scripts/pose.gd` : les poses d'animation (angles des articulations)
- `scripts/rig.gd` : le modèle 3D articulé des personnages
- `scripts/stage.gd` : la construction des décors et de l'éclairage (docks, métro, outils communs)
- `scripts/city.gd` : le Boulevard Néon détaillé (façades, devantures, escaliers de secours, mobilier urbain)
- `scripts/shaders.gd` : les matières procédurales (briques, crépi, asphalte, dalles, fenêtres avec pièces en perspective, tôle ondulée, eau)
- `scripts/sfx.gd` : les bruitages et la musique synthétisés
- `scripts/hud.gd` : la couche 2D
- `scripts/gfx.gd` : niveaux de qualité, brouillard, néons, pluie au sol, post-effets caméra
- `scripts/model_rig.gd` : les personnages 3D importés (GLB/FBX) pilotés par les poses du jeu

Pour régler la difficulté, modifie `HEROES` et `ETYPES` en haut de `main.gd` : points de vie, vitesse, dégâts, portée et délai entre les attaques. Les vagues d'ennemis se règlent dans `STAGES`.
