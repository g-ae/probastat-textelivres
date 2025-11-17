# Projet de Probabilités et statistiques sur l'analyse de textes et livres

## Objectif

## Préparation à l'exécution du code
Tout le projet a été codé sur un seul fichier Julia pour que ce soit plus simple pour nous et éviter de devoir faire des sauvegardes de textes nettoyés ou pas pour pouvoir les passer entre plusieurs scripts.

Une partie du nettoyage du texte utilise la librairie Python `spacy`. Cette librairie nous permet de supprimer tous les pronoms, déterminants, conjonctions, etc. du texte qui nous sont inutiles pour l'analyse. Pour pouvoir l'utiliser en Julia, nous utilisons le package `PythonCall` qui nous permet d'utiliser des outils Python. Exemple d'utlisation de `math.sin` :
```julia
using PythonCall
math = pyimport("math")
math.sin(math.pi / 4)   # => 0.70710678...
```
Par contre il faut d'abord installer le package spacy. Nous l'avons fait sur l'environnement .venv.
```bash
python -m venv .venv
```
Puis entrez dans votre environnement virtuel
```bash
# Windows
/path/to/.venv/bin/Activate.ps1
# Mac/Linux
source /path/to/.venv/bin/activate
```
Ceci vous permet d'installer des librairies Python sans qu'elles soient sauvegardés globalement dans votre ordinateur. \
Ensuite, installez la librairie `spacy`, ainsi que le grand pack de language français `fr_core_news_lg`. \
Vous devrez aussi lancer le script `nettoyage.jl` depuis l'environnement virtuel sinon la variable d'environnement `ENV["VIRTUAL_ENV"]` ne sera pas trouvée.
```bash
pip install spacy
# relancez le terminal et revenez dans le .venv, puis:
spacy download fr_core_news_sm
```
Ensuite, il faut ajouter les packages nécessaires en Julia.
```julia
julia
import Pkg; Pkg.add("PythonCall")
```

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

## Etape 1b : Récupération des textes

L'objectif de base serait que Claude/ChatGPT nous donne directement un lien qu'on peut `curl` et obtenir directement le plain text du livre. Comme ils font trop d'erreurs (livres faux, mauvaise langue, etc), nous avons décidé de demander une liste de livres dans les trois mouvements littéraires spécifiques, puis, comme nous sommes un groupe de trois, chacun prend un mouvement et télécharge les fichiers `.epub` ou `.txt` directement si disponible. \
Les fichiers `.epub` peuvent être passés dans le script Python `epub2txt.py` qui les transforme en `.txt` grâce aux librairies `epub`et `BeautifulSoup`.


## Etape 2 : Nettoyage du texte

```bash
julia analyse.jl
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
- Supprimer pronoms (je,tu,etc), déterminants, conjonctions et ponctuation (peut être prépositions mais à voir.) avec `spacy` qui est une librairie Python. Nous pouvons utiliser cette librairie en Julia en utilisant PythonCall comme mentionné au-dessus.
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


# venv python

```bash
python -m venv .venv
```

## Linux
```bash
source ./.venv/bin/activate
```