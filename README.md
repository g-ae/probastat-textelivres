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

Ce dernier nous donne un fichier CSV avec la classification du mouvement des livres dont nous avons besoin. 

## Etape 1 : Récupération des textes

L'objectif de base serait que Claude/ChatGPT nous donne directement un lien qu'on peut `curl` et obtenir directement le plain text du livre. Comme ils font trop d'erreurs (livres faux, mauvaise langue, etc), nous avons décidé de demander une liste de livres dans les trois mouvements littéraires spécifiques, puis, comme nous sommes un groupe de trois, chacun prend un mouvement et télécharge les fichiers `.epub` ou `.txt` directement si disponible. \
Les fichiers `.epub` peuvent être passés dans le script Python `epub2txt.py` qui les transforme en `.txt` grâce aux librairies `epub`et `BeautifulSoup`.


## Etape 2 : Nettoyage du texte
Pour avoir le nettoyage le plus propre possible, nous allons passer sur tous les textes et les nettoyer avec Python.

```bash
python3 etape2_nettoyage.py
```
Ce programme va chercher directement dans le dossier `book_data/` qui est créé par l'étape précédente.
Nettoyé:
- Supprimer toutes les lignes jusqu'à `Exporté de Wikisource...`
- Supprimer toutes les lignes jusqu'à `MediaWiki`
- Supprimer toutes les lignes jusqu'à la ligne 100 contenant des chiffres romains (I,V,X en majuscule et séparé avec des espaces des autres mots ou "IV.").
- Supprimer toutes les lignes après `À propos de cette édition électronique`
- Mettre tout le texte en minuscule.
- Lignes vides
- [ ] Sauvegarder pour analyse longueur phrases
- Sur tout le texte, chercher les apostrophes (`'`). Si les deux derniers caractères sont `<espace><char>`, remplacer ces trois derniers par `<char>e<espace>`.
- Supprimer pronoms (je,tu,etc), déterminants et conjonctions (peut être prépositions mais à voir.) avec `python spaCy`.
- Regex pour supprimer tout ce qui n'est pas du texte comme les guillements, tiraits, 
- [ ] Save fichier final txt pour analyse.

## Etape 3 : Analyse des textes
L'analyse du texte doit être faite à l'aide du langage de programmation **Julia**.

### Récupérer occurrence des mots

### Base de données FEEL
Nous avons testé l'occurrence des mots avec la base de données [FEEL](http://advanse.lirmm.fr/feel.php) pour avoir une idée de ce que représentent les mots utilisés dans le roman.

### Niveau de langage

### 

## Etape 4 : Affichage des résultats
Pour afficher des résultats, nous avons utilisé **Julia** avec la librairie **Plots**.