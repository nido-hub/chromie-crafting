# Changelog

## 0.4.3

- Fenêtre réductible jusqu'à 740 × 600 sans réduire la police lors du redimensionnement ; taille et position conservées par personnage.
- Disposition compacte automatique : commandes de fabrication sur plusieurs lignes, besoins cumulés sous la file et filtres empilés dans les colonnes étroites.
- Descriptions, composants, recettes et besoins restent accessibles par défilement ; onglets de métiers ajustés à la hauteur disponible.
- Tests de régression sur dix tailles de fenêtre, la mémorisation des dimensions et le retour à la disposition large.
- Rendu et lisibilité des textes longs à confirmer dans le client WoW 3.3.5a.

## 0.4.2

- La croix et Échap ferment immédiatement la fenêtre même en combat, via les gestionnaires sécurisés de WoW. Le déplacement et le redimensionnement restent bloqués en combat.
- Maj + clic gauche sur une ligne de recette insère son lien dans le chat ouvert, sans changer la sélection ni lancer de fabrication. Fonctionne aussi avec les recettes mémorisées et celles du catalogue ayant un identifiant de sort.
- Tests de régression pour la fermeture sécurisée en combat, la libération d'Échap et le partage des recettes.
- Rendu et restrictions réelles du client 3.3.5a à confirmer en jeu.

## 0.4.1

- Correction du compteur fabricable : calcul depuis les composants présents dans les sacs, sans rester bloqué par un compteur natif périmé à zéro.
- Réconciliation du métier actif avec la fenêtre mémorisée lors du retour à son personnage, de l'ouverture du tableau de bord et de `/ccraft` ; plus besoin de changer de métier pour quitter cette consultation.
- Retraits personnels et BDG autorisés depuis les recettes connues mémorisées du personnage connecté, même lorsque le métier natif est fermé. Les autres personnages restent en lecture seule et fabriquer exige toujours un métier ouvert.
- Tests reproduisant les états bloqués de la 0.4.0, dont un retrait BDG partiel avec un autre ingrédient absent et sans API de métier active.
- `/ccraft debug` affiche la version, les états de fenêtre, les droits de retrait BDG et la recette sélectionnée, sans déplacer d'objet ni lancer de craft.
- Vérification en jeu encore nécessaire : si le blocage persiste, lancer `/ccraft debug` au moment du problème et transmettre les lignes affichées.

## 0.4.0

- Cuisine : bouton sécurisé « Créer un feu de camp » pour le sort appris.
- Cuisine : actualisation du feu et des outils chaque seconde, sans changer de recette ni recharger l'addon.
- Correction des compteurs natifs négatifs liés à un outil absent et synchronisation de la sélection avant vérification des outils.
- Retrait bancaire : un ingrédient absent ne bloque plus les suivants ; les stocks partiels sont retirés et les manques restants sont listés.
- Banque de guilde : retrait pour une recette ou une file depuis l'onglet ouvert, dans la limite des permissions et quotas.
- Attente de chargement de l'onglet et des transferts serveur ; arrêt sur fermeture, changement d'onglet, combat ou délai dépassé.
- Aucune fabrication automatique après retrait ; files, favoris et sauvegardes conservés.

### À vérifier en jeu

- Détection d'un feu existant, arrivée/départ à portée, création d'un feu et expiration.
- Retraits BDG selon les droits du personnage et le délai de réponse du serveur.
- Comme en 0.3.0, chaque transfert nécessite une case vide dans un sac général.

## 0.3.0

- Fenêtre commune aux métiers du compte, onglets à icônes et sélection du personnage.
- Favoris persistants et filtre dédié.
- Planification avec les stocks des sacs, de la banque et des autres personnages du même royaume.
- Retrait des composants manquants depuis la banque personnelle pour une recette ou une file.
- Interface opaque brun sombre et or, barre de compétence et panneaux Recette / File séparés.
- Fenêtre compacte et redimensionnable ; conservation des files et des préférences existantes.
- Fermeture différée en combat et contrôles de déplacement/redimensionnement sécurisés.

### Limites

- Client WoW 3.3.5a (30300) uniquement ; rendu réel et comportement serveur à confirmer en jeu.
- Connecter chaque personnage et ouvrir ses métiers et sa banque pour mémoriser ses données.
- Les stocks mémorisés peuvent être périmés et ne garantissent pas qu'un objet soit transférable.
- Le retrait bancaire nécessite une case vide dans un sac général et ne lance aucun craft automatiquement.
