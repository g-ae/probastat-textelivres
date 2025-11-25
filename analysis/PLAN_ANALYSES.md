# Plan d'analyse pour `occurrences_mots` et `longueurs_phrases`

## 1. Objectif

Documenter de manière reproductible toutes les analyses à réaliser avec les scripts `occurrence_mots.jl` et `longueur_phrases.jl`. Ce fichier décrit les entrées/sorties attendues, la procédure pas à pas, les tests statistiques recommandés, les visualisations et les livrables.

---

## 2. Contrat (inputs / outputs / succès)

- Inputs
  - Corpus textuel organisé sous `book_data/` (sous-dossiers par mouvement : `naturalisme`, `romantisme`, ...). Les fichiers peuvent être dans `clean_p1/`, `clean_p2/` ou à la racine du sous-dossier.
  - Fichiers produits par les scripts : `occurrences_mots/<mouvement>_total.txt` et `longueurs_phrases/<mouvement>_total.txt`.
- Outputs attendus
  - Fichiers CSV de statistiques : `analysis/occurrences_<mouvement>_stats.csv`, `analysis/longueurs_<mouvement>_stats.csv`.
  - Figures PNG dans `plots/` et résumés PNG dans `longueurs_phrases/`.
  - Modèles/artefacts dans `models/` (tf-idf, lda, classifier) si réalisés.
- Critères de succès
  - Génération automatique des totaux par mouvement.
  - Production de statistiques descriptives et figures lisibles.
  - Tests statistiques documentés et reproductibles (commandes ou scripts).

---

## 4. Format des fichiers `*_total.txt` (attendu)

Chaque ligne doit être au format :
```
<nbr_mots>: <nbr_phrases>
```
(ex. `12: 153` signifie 153 phrases de 12 mots). Les scripts Julia fournis (`longueur_phrases.jl`) lisent ce format pour calculer des moyennes et tracer des figures.

---

## 5. Étapes détaillées — `occurrences_mots`

1. Générer les totaux par mouvement
   - Par livre : extraire la table fréquence (mot -> count) depuis chaque texte nettoyé.
   - Concaténer les tables par mouvement pour produire `occurrences_mots/<mouvement>_total.txt` (format mot \t count ou CSV). Si déjà présent, vérifier encodage et format.
2. Nettoyage linguistique (optionnel mais recommandé)
   - Lowercasing, suppression de la ponctuation, découpage en mots correct.
   - Suppression des stopwords, option de lemmatisation (avec spaCy ou NLTK) et filtrage par POS (ex. garder noms, verbes si besoin).
   - Documenter chaque pipeline et enregistrer une version nettoyée des totaux.
3. Statistiques descriptives
   - mots (somme des fréquences), types (nombre de mots distincts), hapax (fréq = 1)
   - type-token ratio (TTR = types / mots) et TTR normalisé si nécessaire
   - exporter `analysis/occurrences_<mouvement>_stats.csv` avec colonnes: mouvement, mots, types, hapax, ttr, topN (liste ou lien vers fichier séparé)
4. Comparaisons entre mouvements / livres
   - Fréquences normalisées (par 1000 mots)
   - Calcul log-odds (avec correction) et tests chi-square pour mots spécifiques
   - Extraire mots caractéristiques (positifs/ négatifs) par mouvement
5. Distributions & lois
   - Diagramme rang vs fréquence (Zipf) en log-log, estimer la pente (regression linéaire sur log)
   - Histogramme et CCDF des fréquences
6. N-grams & collocations
   - Extraire bigrams/trigrams fréquents
   - Mesures d’association : PMI, log-likelihood
7. TF-IDF & classification
   - Construire matrice tf-idf par livre
   - Sauvegarder matrice compacte (`models/tfidf.npz` ou CSV)
   - Entraîner classifieurs (SVM, RandomForest) pour prédire mouvement. Exporter modèle dans `models/`.
8. Visualisations
   - Wordclouds par mouvement, heatmaps mots×mouvements, dendrogrammes hierarchiques
9. Avancé (optionnel)
   - Topic modeling (LDA) pour thèmes par mouvement
   - Word embeddings et clustering sémantique

---

## 6. Étapes détaillées — `longueurs_phrases`

1. Extraire les longueurs de phrases par livre
   - Pour chaque livre nettoyé, découper en phrases (utiliser regex simple ou sentence splitter plus robuste) et compter nombres de mots par phrase.
   - Produire pour chaque livre un dictionnaire `nbr_mots => nbr_phrases`.
2. Concaténer par mouvement
   - Additionner les dictionnaires des livres du même mouvement pour produire `longueurs_phrases/<mouvement>_total.txt` (format `nbr_mots: nbr_phrases`).
   - Le script `longueur_phrases.jl` contient des fonctions utiles : `longueur_phrases`, `concat_longueur_dicts`, `save_longueur_phrases`, `moyenne_longueur`, `plot_moyennes`.
3. Statistiques descriptives
   - Par livre et par mouvement : moyenne, médiane, écart-type, skewness, kurtosis
   - Hapax de phrases (longueurs qui n'apparaissent qu'une fois) si pertinent
   - Exporter `analysis/longueurs_<mouvement>_stats.csv` avec colonnes: mouvement, n_phrases_totales, moyenne, mediane, sd, skew, kurt, min, max
4. Visualisations
   - Histogramme et KDE par mouvement
   - Boxplot/Violin plots (ex. `plots/boxplot_longueur.png`)
   - Bar plot des moyennes par mouvement (`longueurs_phrases/moyenne_longueurs_phrases.png`, la fonction `plot_moyennes` le produit)
   - Heatmap longueur_vs_chapitre si découpage en chapitres
5. Ajustement de lois
   - Tester fit des distributions (log-normal, gamma, power-law)
   - Comparer AIC/BIC et utiliser KS test ou Anderson-Darling
6. Comparaisons statistiques
   - Tests de différence des moyennes/ distributions : t-test ou Mann-Whitney, ANOVA ou Kruskal-Wallis
   - Bootstrap pour intervalles de confiance
   - Correction pour comparaisons multiples (Benjamini-Hochberg)
7. Analyses temporelles / structurelles
   - Longueur moyenne par segment du livre (début / milieu / fin), évolution chapitre à chapitre

---

## 7. Analyses croisées (occurrences_mots ↔ longueurs_phrases)

1. Corrélations
   - Corréler longueur moyenne des phrases avec richness lexicale (TTR), hapax ratio, indices de lisibilité
2. Réduction de dimension
   - PCA / t-SNE sur vecteurs TF-IDF + vecteur de features de phrases (moyenne, sd, skew) → visualiser clusters de livres
3. Modélisation
   - Utiliser features combinés (top-N mots, n-grams, statistiques de phrases) pour classer mouvement. Évaluer importance des features (permutation, coefficients, SHAP).

---

## 8. Tests statistiques recommandés

- Tests de fréquences : Chi-square ou log-likelihood pour tables de contingence
- Tests d'ajustement de distribution : KS, Anderson-Darling
- Tests non paramétriques : Mann-Whitney, Kruskal-Wallis
- Intervalles et robustesse : bootstrap / permutation
- Correction pour tests multiples : Benjamini-Hochberg (FDR)

---

## 9. Livrables (fichiers à produire et versionner)

- `analysis/occurrences_<mouvement>_stats.csv` (par mouvement)
- `analysis/longueurs_<mouvement>_stats.csv` (par mouvement)
- Figures : `plots/zipf_<mouvement>.png`, `plots/wordcloud_<mouvement>.png`, `plots/boxplot_longueur.png`, `longueurs_phrases/moyenne_longueurs_phrases.png`
- Artefacts modèles : `models/tfidf.npz`, `models/lda_model.pkl`, `models/classifier.pkl` (optionnel)
- Un README bref (`analysis/README.md`) documentant comment régénérer chaque fichier

---

## 10. Commandes utiles (exemples)

- Calculer la moyenne de longueurs à partir d'un total (Julia) :
```powershell
julia -e "include(\"longueur_phrases.jl\"); println(moyenne_longueur(\"longueurs_phrases/naturalisme_total.txt\"))"
```

- Générer la figure des moyennes (Julia) :
```powershell
julia -e "include(\"longueur_phrases.jl\"); plot_moyennes([\"naturalisme\", \"romantisme\"])"
```

- Exemple rapide TF-IDF en Python (console) :
```powershell
python - <<'PY'
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
# charger vos textes nettoyés et construire la matrice tf-idf
PY
```

---

## 11. Edge cases & vérifications

- Vérifier qu'il n'y a pas de phrases vides après split (le script Julia ignore déjà les phrases vides).
- Vérifier que les fichiers `*_total.txt` existent et sont lisibles (sinon générer avec scripts de preprocessing).
- Gérer encodage non-UTF8 en convertissant les fichiers si besoin.
- Gérer livres très courts (peu de phrases) : exclure ou marquer dans sortie pour éviter biais.

---

## 12. Prochaines étapes recommandées (pratiques)

1. Ajouter un petit script `analysis/make_all.jl` ou `Makefile` pour automatiser :
   - génération des `*_total.txt`, production des CSV statistiques, génération des figures
2. Versionner `analysis/` et `plots/` (sauf modèles très volumineux)
3. Écrire 2-3 tests unitaires pour `longueur_phrases.jl` et `occurrence_mots.jl` (happy path + cas vide)
