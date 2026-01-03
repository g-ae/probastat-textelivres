# Projet de Probabilités et statistiques sur l'analyse de textes et livres

## Objectif

## Etapes projet
Le projet est structuré sur différents fichiers Julia, ici vous trouverez toutes les infos par rapport aux étapes.

### Etape 1 : Prompt IA, récupération des romans
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

### Etape 1b : Récupération des textes

L'objectif de base serait que Claude/ChatGPT nous donne directement un lien qu'on peut `curl` et obtenir directement le plain text du livre. Comme ils font trop d'erreurs (livres faux, mauvaise langue, etc), nous avons décidé de demander une liste de livres dans les trois mouvements littéraires spécifiques, puis, comme nous sommes un groupe de trois, chacun prend un mouvement et télécharge les fichiers `.epub` ou `.txt` directement si disponible. \
Les fichiers `.epub` peuvent être passés dans le script Python `epub2txt.py` qui les transforme en `.txt` grâce aux librairies `epub`et `BeautifulSoup`.


### Etape 2 : Nettoyage du texte
Une partie du nettoyage du texte utilise la librairie Python `spacy`. Cette librairie nous permet de supprimer tous les pronoms, déterminants, conjonctions, etc. du texte qui nous sont inutiles pour l'analyse. Pour pouvoir l'utiliser en Julia, nous utilisons le package [PythonCall](https://github.com/JuliaPy/PythonCall.jl) qui nous permet d'utiliser des outils Python. Exemple d'utlisation de `math.sin` :
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
Ensuite, installez la librairie `spacy`, ainsi que le petit pack de language français `fr_core_news_sm`. (Utilisé petit pack car cela améliore les performances d'analyse des fichiers. Utile car nous devons tourner spacy sur 100 fichiers) \

```bash
pip install spacy
# relancez le terminal, revenez dans le .venv, puis:
spacy download fr_core_news_sm
```
Ensuite, il faut ajouter le packages nécessaires en Julia.
```julia
julia
import Pkg; Pkg.add("PythonCall")
```
Vous pourrez ensuite lancer le script de nettoyage avec :
```bash
# IMPORTANT -> il faut être dans l'environnement virtuel pour que le scripts fonctionne correctement
julia nettoyage.jl
```
Ce programme va chercher directement dans le dossier `book_data/` qui est créé par l'étape précédente. \
Ce qu'il fait sur chaque fichier :
- Supprimer toutes les lignes jusqu'à `Exporté de Wikisource...`
- Supprimer toutes les lignes jusqu'à `MediaWiki`
- Supprimer toutes les lignes jusqu'à la ligne 100 contenant des chiffres romains (I,V,X en majuscule et séparé avec des espaces des autres mots ou "IV.").
- Supprimer toutes les lignes après `À propos de cette édition électronique`
- Mettre tout le texte en minuscule.
- Lignes vides
- [ ] Sauvegarder pour analyse longueur phrases sous `book_data/\<mouvement\>/clean_p1/\<nom\>.txt
- Sur tout le texte, chercher les apostrophes (`'`). Si les deux derniers caractères sont `<espace><char>`, remplacer ces trois derniers par `<char>e<espace>`.
- Supprimer pronoms (je,tu,etc), déterminants, conjonctions et ponctuation (peut être prépositions mais à voir.) avec `spacy` qui est une librairie Python. Nous pouvons utiliser cette librairie en Julia en utilisant PythonCall comme mentionné au-dessus.
- [ ] Save fichier final sous `book_data/\<mouvement\>/clean_p2/\<nom\>.txt pour analyse.

### Etape 3 : Analyse des textes
L'analyse des textes est faite dans le fichier `analyse.jl`. Chaque méthode est écrite dans une fonction différente, ceci permet d'être plus flexible dans le cas où on voudrait changer quelque chose dans le futur.

#### Occurrence des mots

#### Base de données FEEL
Nous avons testé l'occurrence des mots avec la base de données [FEEL](http://advanse.lirmm.fr/feel.php) pour avoir une idée de ce que représentent les mots utilisés dans le roman. \
Le fichier CSV est structuré ainsi :
```
id;word;polarity;joy;fear;sadness;anger;surprise;disgust
...
273;compétitif;negative;0;0;0;1;0;0
274;complètement;positive;0;0;0;0;0;0
275;comploter;negative;0;1;0;1;0;0
```
Nous allons uniquement utiliser les classifications de sentiment. Le chiffre affiché est utilisé comme des points. \
Exemple : L'analyse d'occurrence des mots a compté le mot `comploter` 132 fois. Vu que ce mot représente les sentiments `fear` et `anger`, on donne le nombre de fois que `comploter` apparaît dans le texte en points à ces sentiments là, donc :
```julia
sentiments["fear"] += occurrence["comploter"]
sentiments["anger"] += occurrence["comploter"]
```
Si le mot cherché n'existe pas dans la base de données `FEEL`, on le considère comme un mot neutre, sans émotion.

Cette analyse est présente sur le fichier `analyse_feel.jl`, qui contient la fonction
```julia
function analyse_feel(lines_livre)
end
```
Pour l'utiliser, il vous faudra installer les packages `CSV` et `DataFrames` en Julia.
```bash
julia
import Pkg; Pkg.add("CSV")
```
Vous pouvez ensuite `include('analyse_feel.jl')`, ce qui vous donnera accès à la fonction `analyse_feel(lines)` dans votre code. Ceci vous retournera un dictionnaire contenant un ratio de chaque sentiment.
```julia
# Exemple de retour
{
  "joy": 0.23,
  "fear": 0.11,
  "sadness": 0.34,
  "anger": 0.05,
  "surprise": 0.19,
  "disgust": 0.08
}
```
#### Longueur des phrases

#### Niveau de langage

#### Classification de mots

## Etape 4 : Affichage des résultats
Pour afficher des résultats, nous avons utilisé **Julia** avec la librairie **Plots**.

## Sources
Abdaoui, Amine and Azé, Jérôme and Bringay, Sandra and Poncelet, Pascal (2017). FEEL: a French Expanded Emotion Lexicon. *Language Resources and Evaluation*, *51*. https://doi.org/10.1007/s10579-016-9364-5
