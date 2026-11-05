# Chromie Crafting — 0.3.0

Addon français pour WoW 3.3.5a (30300), installé dans son propre dossier.

## Utilisation

1. **Quitter complètement WoW puis le relancer** pour détecter le nouvel addon.
2. Activer **Chromie Crafting** dans la liste des addons du personnage.
3. Ouvrir un métier normalement depuis le grimoire.

Un **clic sur le bouton marteau de la minimap** ouvre la fenêtre des métiers du
compte. **Clic droit** conserve le lanceur rapide des métiers du personnage.
Glisser le bouton pour le
déplacer autour de la minimap ; sa position est mémorisée par personnage.
Le lanceur est indisponible en combat et pendant une fabrication en cours.

La nouvelle fenêtre remplace celle de Blizzard. Déplaçable par glisser-déposer,
elle adapte son échelle à la taille de l'écran. Échap ferme la fenêtre.

**Redimensionnement :** tirer la poignée du coin inférieur droit. La largeur
des colonnes et le nombre de lignes visibles s'adaptent sans grossir le texte.
La taille est mémorisée par personnage et limitée à la taille de l'écran.
La taille minimum conserve la disposition et la lisibilité des contrôles.
La nouvelle surface minimum est de 980 × 740, réduite automatiquement sur les petits écrans.
Après un changement de résolution ou d'échelle de l'interface pendant la session,
faire `/reload` pour recalculer les limites de redimensionnement.

Les recettes, les composants et la liste des besoins affichent maintenant leurs
icônes ; le résultat sélectionné possède aussi une grande icône avec infobulle.
Les champs de texte ont un cadre complet, des marges intérieures et une largeur
permettant d'afficher les quatre chiffres des quantités.

- Catégories repliables ; compétence par défaut : orange, jaune, vert, gris.
- Recherche par nom/catégorie, filtres connues/à apprendre/fabricables.
- Autres tris **à l'intérieur des catégories** : nom ou quantité fabricable.
- Quantité de **1 à 9999 opérations** ; « Maximum » utilise les sacs, jamais les stocks distants.
- « Fabriquer » lance uniquement la recette sélectionnée, sans modifier la file.
- « Ajouter à la file » prépare plusieurs recettes, même sans les composants.
- Quantité d'une ligne : modifier puis Entrée. `^`/`v` réordonnent, `x` retire.
- La file et ses quantités restantes sont sauvegardées **par personnage et métier**.
- La molette ou les boutons `<`/`>` font défiler les listes.
- Les besoins cumulés comptent chaque composant une seule fois selon les options de stocks.
- Aucun lancement automatique à l'ouverture ou après reconnexion.

**Fabriquer consomme réellement les composants.** Un clic lance un lot d'une même
recette avec la répétition native de WoW, limité aux composants disponibles.
Chaque succès confirmé diminue la quantité restante. Pour passer à la recette
suivante, cliquer à nouveau sur « Lancer la file » : WoW bloque les lancements
automatiques hors clic utilisateur. La fabrication s'arrête sur interruption,
composants manquants, outil absent, recharge, fermeture ou combat.
Relancer après avoir réglé le problème. Les opérations déjà terminées restent décomptées.

### Premier essai conseillé

Choisir une recette peu coûteuse, lancer deux opérations, puis essayer une file
de deux recettes. Interrompre un craft pour vérifier que seule la quantité
effectivement terminée est décomptée. Comparer ensuite les composants et les
recettes connues avec la fenêtre Blizzard. Les tests hors jeu ne peuvent pas
confirmer le comportement exact du serveur.

## Métiers du compte et favoris

### Apparence 0.3.0

L'interface reprend la disposition des métiers de WoW récent : panneaux brun
sombre opaques, contours dorés, icône et barre de compétence en haut, catégories
à gauche et fiche recette à droite. Les métiers du compte sont des **onglets à
icônes sur le bord droit** ; les survoler affiche leur nom.
Les fonds sont dessinés directement, sans les textures de tooltip qui peuvent
être transparentes avec certains packs du client.

Les boutons **Recette** et **File de fabrication** changent le panneau de droite,
sans perdre la sélection ni les quantités. Les composants ont de grandes icônes
avec un détail explicite sacs / banque / autres sous chaque nom.
Les boutons de retrait restent respectivement dans la fiche recette et dans la file.

Au premier chargement de cette apparence, la taille et la position de la fenêtre
sont réinitialisées une seule fois pour éviter de conserver l'ancienne fenêtre
plein écran ou décalée. **Aucune recette, file, préférence de stocks ou favori n'est
effacé.** Les déplacements et tailles choisis ensuite restent mémorisés.

Les onglets de métiers utilisent des boutons sécurisés de WoW. En combat,
le déplacement, le redimensionnement et le retour à Blizzard sont bloqués ;
une fermeture demandée par Échap, la croix ou le métier est différée jusqu'à
la sortie de combat.

- Un onglet à icône par métier de fabrication découvert, puis un sélecteur de personnage.
  Cliquer sur l'onglet d'un métier appris du personnage connecté ouvre réellement
  ce métier ; les autres métiers sont consultés à partir des données mémorisées.
- Pour remplir le catalogue du compte, connecter chaque personnage avec l'addon
  activé et ouvrir chacun de ses métiers au moins une fois. Refaire cette opération
  après apprentissage de nouvelles recettes. Les personnages jamais visités ne
  peuvent pas être découverts par l'API de WoW.
- Les métiers et stocks sont partagés entre personnages de cette installation,
  sur le **même royaume** ; les métiers d'un autre personnage ne permettent jamais
  de fabriquer à sa place. La banque de guilde et le courrier ne sont pas inclus.
- Le bouton `+` d'une recette la marque comme favorite (`*`), un second clic la
  retire. Le bouton **Favoris** filtre la liste. Les favoris sont mémorisés par
  personnage connecté et métier ; ils s'appliquent aussi aux recettes consultées.
- Les anciennes files de fabrication, positions et dimensions par personnage
  sont conservées. La file d'un autre personnage est consultable en lecture
  seule, telle que mémorisée lors de sa dernière connexion.

## Banque et inventaires des autres personnages

Les cases **Inclure la banque** et **Inclure les autres personnages** sont
indépendantes, désactivées par défaut et mémorisées par personnage. Elles modifient
les quantités **planifiables**, leur filtre/tri, les composants et les besoins de
la file. Chaque composant affiche **disponible / requis**, puis un détail nommé
**sacs / banque / autres** sur la ligne suivante.
La banque des autres personnages n'est ajoutée que si les deux cases sont cochées.

Les sacs des autres personnages correspondent à leur dernière visite avec l'addon ;
leur banque, à sa dernière ouverture. Une banque jamais visitée n'est pas connue.
Ces stocks peuvent être périmés ou contenir des objets liés : les quantités
planifiables ne garantissent pas qu'un transfert soit possible.
Le compteur **Sacs** et les boutons de fabrication restent limités aux composants
réellement disponibles pour le métier ouvert, indépendamment de ces options.

### Retirer les composants à la banque

1. Ouvrir sa **banque personnelle** et son métier sur le personnage connecté.
2. Choisir une recette et une quantité d'opérations, puis **Retirer composants** ;
   ou préparer une file et utiliser **Retirer pour la file**.
3. L'addon retire uniquement ce qui manque dans les sacs, attend la confirmation
   de chaque transfert, et ne déclenche **aucun craft automatiquement**.
4. Cliquer ensuite sur **Fabriquer** ou **Lancer la file**.

Le retrait s'arrête si la banque ou la fenêtre se ferme, en combat, sur un objet
verrouillé, un curseur occupé ou une confirmation absente. **Arrêter** annule aussi
la suite des retraits ; les composants déjà déplacés restent dans les sacs.
Un stock insuffisant produit un retrait partiel avec un message explicite.
Par sécurité, chaque transfert utilise une **case vide d'un sac général** : libérer
une case même si une pile existante pourrait théoriquement accueillir les objets.
L'addon ne supprime aucun objet, n'échange pas des objets différents et ne retire
jamais de composants de la banque d'un autre personnage.

## Retour à Blizzard

Bouton « Fenêtre Blizzard » ou `/ccraft blizzard` ; choix mémorisé.
`/ccraft` ou `/metiers` réactive la nouvelle interface. Aucun addon existant modifié.

## Limites connues

- Les métiers de fabrication utilisent l'API TradeSkill de 3.3.5a : alchimie,
  forge, couture, travail du cuir, ingénierie, joaillerie, calligraphie,
  enchantement, cuisine, secourisme et fonte. Pêche, dépeçage, herboristerie
  et extraction minière n'ont pas de liste de crafts à remplacer.
- Les métiers liés sont consultables mais ne permettent pas de fabriquer.
- Les enchantements nécessitant une cible restent **manuels**, un par un :
  choisir l'objet ou le vélin, puis relancer pour l'enchantement suivant.
  Aucun ciblage ou usage de vélin automatique.
- AtlasLoot et AtlasLoot_Crafting sont **facultatifs** mais nécessaires au
  catalogue des recettes inconnues et aux catégories enrichies. Sans eux,
  l'addon utilise les recettes apprises et les catégories natives.
- Le catalogue AtlasLoot installé est ancien et n'est pas une base de données
  ChromieCraft : recettes retirées, autres spécialisations ou contenus non ouverts
  peuvent apparaître. Les recettes inconnues sont classées par nom après les
  connues ; leur niveau requis et leurs composants ne sont pas inventés.
- Pas de sous-crafts automatiques, ni de calcul d'achats/hôtel des ventes.
  Les besoins sont bruts : les produits d'une recette de la file ne sont pas
  soustraits des composants d'une autre. Organiser soi-même les sous-crafts.
- Les composants en banque comptent dans la planification si l'option est cochée,
  mais doivent être retirés avant de fabriquer.
- Première version : rendu réel et enchaînement serveur à valider en jeu,
  notamment pour les enchantements et les crafts instantanés.
- Si aucune confirmation n'arrive après deux minutes, l'addon suspend la suite
  mais conserve le suivi de l'opération pour compter un éventuel succès tardif.
  Choisir la cible ou annuler l'action ; si le serveur ne confirme rien,
  vérifier les quantités réellement fabriquées avant de faire `/reload`.

## Tests de développement

`python Interface/AddOns/ChromieCrafting/tests/run.py` depuis le dossier WoW.
Nécessite `lupa` sur la machine de développement seulement (rien à installer pour jouer).
Les tests exécutent le Lua 5.1 et simulent la frontière de l'API WoW ; ils ne
remplacent pas une vérification dans le client.
