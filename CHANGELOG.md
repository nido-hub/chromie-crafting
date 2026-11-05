# Changelog

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
