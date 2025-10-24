# Projet de Probabilités et statistiques sur l'analyse de textes et livres

## Objectif

## Etape 1 : Prompt IA, récupération des romans
Pour créer une liste de romans des mouvements voulus, nous avons fait recours à l'IA pour nous créer un fichier CSV avec les informations dont nous avons besoin pour faire cette analyse. Voici le prompt utilisé avec Claude :

```
Donne moi des romans français **obligatoirement écrits en français** qui ont été écrits dans la période de 1700 à 1900. Je veux uniquement des livres des mouvements des Lumières, romantisme et naturalisme. Je veux ~29-36 romans de chaque mouvement littéraire.
Je veux que tu me donnes ces données en forme CSV avec points-virgule (';') avec headers. Chaque donnée devra avoir des double guillements ("), exemple: "Émile Zola". 
La manière d'écrire le mouvement doit être uniforme et doit correspondre à un de ces trois: "lumieres", "romantisme" ou "naturalisme".
Le champ URL doit contenir un URL vers le plain text du livre cité sur WIKIMEDIA OBLIGATOIREMENT.
Le champ "nom_fichier" doit être complété avec le titre du roman et nom de l'auteur, dans le sens où, pour le roman Candide, ou l'Optimisme de Voltaire, tu mets dans le champ "candideouloptimisme_voltaire.txt", pour éviter des erreurs de file system.
Si besoin, tu peux chercher sur le web.

TITRE;AUTEUR;MOUVEMENT;URL;NOM_FICHIER
```

Ce dernier nous donne un fichier CSV avec la classification du mouvement des livres dont nous avions besoin. Nous pouvons ensuite récupérer tous les fichiers texte avec la commande python :

```bash
python3 etape1_recuptxt.py data.csv
```

### Problèmes rencontrés
Réponse de `https://fr.wikisource.org` :
```
Please set a user-agent and respect our robot policy https://w.wiki/4wJS. See also T400119.
```
Résolution: `https://wikitech.wikimedia.org/api/rest_v1/#/Page%20content/get_page_`

## Etape 2 : Nettoyage du texte
Pour avoir le nettoyage le plus propre possible, nous allons passer sur tous les textes et les nettoyer avec Python.

```bash
python3 etape2_nettoyage.py
```

Ce programme va chercher directement dans le dossier `book_data/` qui est créé par l'étape précédente.

## Etape 3 : Analyse des textes
L'analyse du texte doit être faite à l'aide du langage de programmation **Julia**.

### Récupérer occurrence des mots

### Base de données FEEL
Nous avons testé l'occurrence des mots avec la base de données [FEEL](http://advanse.lirmm.fr/feel.php) pour avoir une idée de ce que représentent les mots utilisés dans le roman.

### Niveau de langage

### 

## Etape 4 : Affichage des résultats
Pour afficher des résultats, nous avons utilisé **Julia** avec la librairie **Plots**.