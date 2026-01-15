using Plots
using Measures

include("occurrences_mots/blacklist.jl")

function clean_word(word::AbstractString)
    return strip(word, ['.', ',', '!', '?', ';', '"', '\'', '(', ')', '[', ']', '{', '}', '-'])
end

function occurrence_mots(text::String)
    # Retourne un dictionnaire avec l'occurrence de chaque mot dans le texte
    # mot => occurrence
    res = Dict{String, Int}()
    words = split(text)

    for w in words
        word = clean_word(w)
        if haskey(res, word)
            res[word] += 1
        else
            res[word] = 1
        end
    end

    return res
end

function save_occurrence_mots(occ_dict::Dict{String, Int}, output_file::String, threshold::Int=0)
    dir = dirname(output_file)
    if !isempty(dir) && dir != "." && !isdir(dir)
        mkpath(dir)
    end

    filtered = occurrences_greater_than(occ_dict, threshold)
    total_mots = sum(values(filtered))

    open(output_file, "w") do f
        println(f, "mot;occurrence;frequence")
        for (word, count) in filtered
            println(f, "$word;$count;$(round(count / total_mots, digits=4))")
        end
    end
end

function concat_occurrence_dicts(dicts::Vector{Dict{String, Int}})
    res = Dict{String, Int}()

    for dict in dicts
        for (word, count) in dict
            if haskey(res, word)
                res[word] += count
            else
                res[word] = count
            end
        end
    end

    return res
end

function highest_occurrences(occ_dict::Dict{String, Int}, n::Int)
    sorted_words = sort(collect(occ_dict), by=x->x[2], rev=true)
    return sorted_words[1:min(n, length(sorted_words))]
end

# Threshold is exclusive
function occurrences_greater_than(occ_dict::Dict{String, Int}, threshold::Int)
    res = Dict{String, Int}()

    for (word, count) in occ_dict
        if count > threshold
            res[word] = count
        end
    end

    return res
end

function nb_unique_words(occ_dict::Dict{String, Int})
    return length(occ_dict)
end

function find_min_occurrence(occ_dict::Dict{String, Int})
    if isempty(occ_dict)
        return 0
    end

    return minimum(values(occ_dict))
end

function find_max_occurrence(occ_dict::Dict{String, Int})
    if isempty(occ_dict)
        return 0
    end

    return maximum(values(occ_dict))
end

function nb_mots_pour_occurrence(occ_dict::Dict{String, Int}, occurrence::Int)
    total = 0

    for (word, count) in occ_dict
        if count == occurrence
            total += 1
        end
    end

    return total
end

function nb_mots_par_occurrence(occ_dict::Dict{String, Int})
    res = Dict{Int, Int}()

    min_occ = find_min_occurrence(occ_dict)
    max_occ = find_max_occurrence(occ_dict)

    for occ in min_occ:max_occ
        res[occ] = nb_mots_pour_occurrence(occ_dict, occ)
    end

    return res
end

function process_file(file_path::String)
    lines = []
    open(file_path) do f
        lines = readlines(f)
    end

    if isempty(lines)
        return nothing
    end

    return occurrence_mots(join(lines, " "))
end

function process_mouvement(mouvement::String, threshold::Int=0)
    base_path = pwd() * "/book_data/" * mouvement * "/clean_p2/"
    all_files = readdir(base_path)
    book_files = filter(f -> contains(f, '.'), all_files)

    dicts::Vector{Dict{String, Int}} = []

    for (i, file_name) in enumerate(book_files)
        full_path = base_path * file_name
        println("$mouvement: $file_name ($i/$(length(book_files)))")

        occ_dict = process_file(full_path)

        if occ_dict === nothing
            println("   -> skipped (empty file)")
            continue
        end

        out_path = "occurrences_mots/frequence/" * mouvement * "/" * splitext(file_name)[1] * ".csv"
        save_occurrence_mots(occ_dict, out_path, threshold)

        push!(dicts, occurrences_greater_than(occ_dict, threshold))
    end

    total_occ = concat_occurrence_dicts(dicts)
    save_occurrence_mots(total_occ, "occurrences_mots/frequence/" * mouvement * "_total_" * string(threshold) * ".csv")

    return total_occ
end

# Pour l'oral de mi-projet, à séparer et compléter plus tard
function plot_total_and_unique_separately(occ_dicts::Vector{Dict{String,Int}}, mouvements::Vector{String})
    n = length(mouvements)
    total_words  = [sum(values(d)) for d in occ_dicts]
    unique_words = [length(d) for d in occ_dicts]

    println("--- Global Stats for all movements ---")
    for i in 1:n
        println("Movement: $(mouvements[i])")
        println("  Total words: $(total_words[i])")
        println("  Unique words: $(unique_words[i])\n")
    end

    # Save in CSV
    open("occurrences_mots/stats_globales_plots.csv", "w") do f
        println(f, "mouvement;motal_mots;mots_uniques") # En-tête
        for i in 1:n
            println("Movement: $(mouvements[i])")
            println("  Total words: $(total_words[i])")
            println("  Unique words: $(unique_words[i])\n")

            # Écriture ligne CSV
            println(f, "$(mouvements[i]);$(total_words[i]);$(unique_words[i])")
        end
    end
    println("Stats sauvegardées dans : occurrences_mots/stats_globales_plots.csv")

    dir = "occurrences_mots/"
    if !isdir(dir)
        mkpath(dir)
    end

    palette = [:blue, :green, :red]
    colors = [palette[(i - 1) % length(palette) + 1] for i in 1:length(mouvements)]

    # Plot total words
    bar(mouvements, total_words;
        color = colors,
        title = "Total de mots par mouvement",
        xlabel = "Mouvement", ylabel = "Nombre de mots",
        legend = false,
        bottom_margin = 10mm, left_margin = 6mm, right_margin = 4mm, top_margin = 10mm
    )
    # Annotate total words
    for i in 1:n
        annotate!(i, total_words[i] + total_words[i]*0.02, text(string(total_words[i]), :center, 8))
    end
    savefig(dir * "total_words_by_movement.png")
    println("Plot saved to: $(dir)total_words_by_movement.png")

    # Plot unique words
    bar(mouvements, unique_words;
        color = colors,
        title = "Nombre de mots uniques par mouvement",
        xlabel = "Mouvement", ylabel = "Nombre de mots",
        legend = false,
        bottom_margin = 10mm, left_margin = 6mm, right_margin = 4mm, top_margin = 10mm
    )
    # Annotate unique words
    for i in 1:n
        annotate!(i, unique_words[i] + unique_words[i]*0.02, text(string(unique_words[i]), :center, 8))
    end
    savefig(dir * "unique_words_by_movement.png")
    println("Plot saved to: $(dir)unique_words_by_movement.png")
end

function plot_stats_for_movement(occ_dict::Dict{String,Int}, mouvement::String; top_n=10)
    dir = "occurrences_mots/"
    if !isdir(dir)
        mkpath(dir)
    end

    # Total words
    total_words = sum(values(occ_dict))
    unique_words = length(occ_dict)
    println("--- Stats for $mouvement ---")
    println("Total words: $total_words")
    println("Unique words: $unique_words")

    # Top N most frequent words
    top_words = sort(collect(occ_dict), by = x->x[2], rev=true)[1:min(top_n, unique_words)]
    words  = [p[1] for p in top_words]
    counts = [p[2] for p in top_words]

    palette = [:blue, :green, :red, :orange, :purple, :cyan]
    colors = [palette[(i-1) % length(palette) + 1] for i in 1:length(words)]

    bar(words, counts;
        color = colors,
        title = "Top $top_n mots — $mouvement",
        xlabel = "Mot", ylabel = "Occurrences",
        legend = false,
        rotation = 45,
        bottom_margin = 10mm, left_margin = 6mm, right_margin = 4mm, top_margin = 10mm
    )
    # Annotate top words
    maxv = isempty(counts) ? 0.0 : maximum(counts)
    offset = maxv * 0.03
    for (i, v) in enumerate(counts)
        annotate!(i, v + offset, text(string(v), :center, 8))
    end

    savefig(dir * "top_" * string(top_n) * "_words_" * mouvement * ".png")
    println("Saved: $(dir)top_$(top_n)_words_$mouvement.png")
end

function generate_data_mi()
    mouvements = ["lumieres", "naturalisme", "romantisme"]
    for m in mouvements
        process_mouvement(m)
    end
end

function generate_plots_mi()
    mouvements = ["lumieres", "naturalisme", "romantisme"]
    threshold = 5
    all_occ_dicts::Vector{Dict{String, Int64}} = []
    for m in mouvements
        occ_mvt = process_mouvement(m, threshold)
        push!(all_occ_dicts, occ_mvt)
    end
    plot_total_and_unique_separately(all_occ_dicts, mouvements)
    for (i, m) in enumerate(mouvements)
        plot_stats_for_movement(all_occ_dicts[i], m; top_n=10)
    end
end


# Analyse de Spécificité
"""
Cette fonction compare les vocabulaires pour trouver les mots-clés typiques.
Elle calcule un ratio : (Fréquence dans le mouvement) / (Fréquence globale).
Si le ratio > 1, le mot est sur-représenté.
"""
function analyser_specificite_mouvements(mouvements::Vector{String}, seuil_frequence::Int=50)
    println("=======================================================")
    println("ANALYSE DES MOTS DISCRIMINANTS (SPÉCIFICITÉ)")

    # BLACKLIST (Patronymes, lieux uniques et bruit) - Liste générée par IA
    blacklist = get_blacklist()

    # Open CSV for output
    output_csv = "occurrences_mots/mots_discriminants.csv"
    f_csv = open(output_csv, "w")
    println(f_csv, "mouvement;rang;mot;score") # En-tête

    # Charger tous les dictionnaires
    dicts_par_mvt = Dict{String, Dict{String, Int}}()
    total_mots_par_mvt = Dict{String, Int}()

    # Dictionnaire global
    dict_global = Dict{String, Int}()
    total_mots_global = 0

    for m in mouvements
        path = ["occurrences_mots/frequence/" * m * "_total_0.csv"]
        filename = ""
        for p in path
            if isfile(p)
                filename = p
                break
            end
        end

        if filename == ""
            println("Fichier introuvable pour le mouvement '$m'.")
            return
        end

        d = Dict{String, Int}()

        open(filename, "r") do f
            for line in eachline(f)
                if startswith(line, "mot;") continue end

                parts = split(line, ";")

                if length(parts) >= 2
                    mot = String(parts[1])

                    try
                        # On essaie de lire l'occurrence (parts[2])
                        count = parse(Int, parts[2])

                        d[mot] = count
                        dict_global[mot] = get(dict_global, mot, 0) + count
                    catch e
                        continue
                    end
                end
            end
        end

        dicts_par_mvt[m] = d
        total_mots_par_mvt[m] = sum(values(d))
        println("Mouvement $m chargé : $(length(d)) mots uniques.")
    end

    total_mots_global = sum(values(dict_global))

    # Calcul des scores de spécificité
    for m in mouvements
        scores = Tuple{String, Float64}[]
        d_mvt = dicts_par_mvt[m]
        total_mvt = total_mots_par_mvt[m]

        for (mot, count) in d_mvt
            if count < seuil_frequence
                continue
            end

            if mot in blacklist
                continue
            end

            # Calcul des fréquences relatives (probabilité d'apparition)
            freq_rel_mvt = count / total_mvt
            freq_rel_global = dict_global[mot] / total_mots_global

            # Score = Ratio de sur-représentation
            score = freq_rel_mvt / freq_rel_global

            push!(scores, (mot, score))
        end

        # Trier par score décroissant
        sort!(scores, by = x -> x[2], rev = true)

        # Affichage du Top 20
        println("TOP 20 MOTS TYPIQUES : $(uppercase(m))")

        for i in 1:min(20, length(scores))
            mot, score = scores[i]
            println("  $i. $mot (x$(round(score, digits=1)))")

            # Save in CSV
            println(f_csv, "$m;$i;$mot;$(round(score, digits=4))")
        end
    end

    # Close CSV
    close(f_csv)
    println("Mots discriminants sauvegardés dans : $output_csv")

    println("=======================================================")
end

"""
Calcule le Type-Token Ratio (TTR).
TTR = (Nombre de mots uniques) / (Nombre total de mots).
Un TTR élevé indique un vocabulaire riche et varié.
"""
function analyser_richesse_lexicale(mouvements::Vector{String})
    println("=======================================================")
    println("ANALYSE DE LA RICHESSE LEXICALE (TTR)")
    println("Calcul du ratio : (Mots Uniques / Mots Totaux) * 100")

    # Open CSV for output
    output_csv = "occurrences_mots/resultats_ttr.csv"
    f_csv = open(output_csv, "w")
    println(f_csv, "mouvement;mots_totaux;mots_uniques;ttr_pourcentage")

    for m in mouvements
        filename = "occurrences_mots/frequence/" * m * "_total_0.csv"

        if !isfile(filename)
            println("Fichier introuvable : $filename")
            continue
        end

        mots_uniques = 0
        mots_totaux = 0

        open(filename, "r") do f
            for line in eachline(f)
                if startswith(line, "mot;") continue end

                parts = split(line, ";")
                if length(parts) >= 2
                    try
                        count = parse(Int, parts[2])
                        mots_uniques += 1      # C'est une ligne valide, donc un mot unique
                        mots_totaux += count   # On ajoute toutes les fois où il apparait
                    catch e
                        continue
                    end
                end
            end
        end

        if mots_totaux == 0
            println("$m : Données vides.")
            continue
        end

        # Calcul du pourcentage
        ttr = (mots_uniques / mots_totaux) * 100

        println("Mouvement : $(uppercase(m))")
        println("Mots Totaux  : $mots_totaux")
        println("Mots Uniques : $mots_uniques")
        println("Score TTR    : $(round(ttr, digits=4)) %")

        # Save in CSV
        println(f_csv, "$m;$mots_totaux;$mots_uniques;$(round(ttr, digits=4))")
    end

    # Close CSV
    close(f_csv)
    println("Résultats TTR sauvegardés dans : $output_csv")
    println("=======================================================")
end


"""
Charge les données de référence (CSV) en mémoire pour la comparaison.
"""
function charger_reference(mouvements::Vector{String})
    refs = Dict{String, Dict{String, Int}}()
    println("========================================================")
    println("Chargement des données de référence")
    for m in mouvements
        path = "occurrences_mots/frequence/" * m * "_total_0.csv"

        if !isfile(path)
            println("Fichier de référence manquant pour $m : $path")
            continue
        end

        d = Dict{String, Int}()
        open(path, "r") do f
            for line in eachline(f)
                if startswith(line, "mot;") continue end # Sauter l'en-tête
                parts = split(line, ";")
                if length(parts) >= 2
                    try
                        d[String(parts[1])] = parse(Int, parts[2])
                    catch; end
                end
            end
        end
        refs[m] = d
    end
    return refs
end


"""
Vérifie la Loi de Zipf pour chaque mouvement.
Trace Log(Fréquence) en fonction de Log(Rang).
Si c'est une droite, la loi est vérifiée.
"""
function verifier_loi_zipf()
    println("=======================================================")
    println("ANALYSE DE LA LOI DE ZIPF")

    mouvements = ["lumieres", "naturalisme", "romantisme"]
    donnees = charger_reference(mouvements)

    # Création du dossier pour les plots
    dir = "occurrences_mots/"
    if !isdir(dir); mkpath(dir); end

    # Initialisation du graphique
    p = plot(
        title = "Loi de Zipf : Log(Fréquence) vs Log(Rang)",
        xlabel = "Log(Rang)",
        ylabel = "Log(Fréquence)",
        legend = :topright
    )

    colors = Dict("lumieres" => :blue, "naturalisme" => :green, "romantisme" => :red)

    for m in mouvements
        # Récupération des fréquences
        d = donnees[m]
        counts = collect(values(d))

        # Tri décroissant (Du plus fréquent au moins fréquent)
        sort!(counts, rev=true)

        # On calcule les Rangs (1, 2, 3...)
        ranks = 1:length(counts)

        # Transformation Logarithmique
        log_ranks = log10.(ranks)
        log_freqs = log10.(counts)

        # Ajout de la courbe au graphique
        plot!(p, log_ranks, log_freqs,
              label = uppercase(m),
              color = get(colors, m, :black),
              linewidth = 2,
              alpha = 0.8)

        println("Courbe générée pour : $m")
    end

    # Sauvegarde
    output_path = dir * "loi_de_zipf.png"
    savefig(p, output_path)
    println("Graphique sauvegardé : $output_path")
    println("=======================================================")
end

"""
Calcule la similarité Cosinus entre deux dictionnaires de fréquence.
Retourne une valeur entre 0 (différent) et 1 (identique).
Prend en compte la fréquence relative pour ignorer la taille des textes.
"""
function calcul_similarite_cosinus(dict_texte::Dict{String, Int}, dict_ref::Dict{String, Int})
    # Calcul des totaux pour passer en fréquence
    total_texte = sum(values(dict_texte))
    total_ref = sum(values(dict_ref))

    # Identification des mots communs (le produit scalaire ne se fait que sur l'intersection)
    mots_communs = intersect(keys(dict_texte), keys(dict_ref))

    produit_scalaire = 0.0

    # Calcul du Numérateur (A . B)
    for mot in mots_communs
        freq1 = dict_texte[mot] / total_texte
        freq2 = dict_ref[mot] / total_ref
        produit_scalaire += freq1 * freq2
    end

    # Calcul des Normes (||A|| * ||B||)
    norme_texte = sqrt(sum([(c/total_texte)^2 for c in values(dict_texte)]))
    norme_ref = sqrt(sum([(c/total_ref)^2 for c in values(dict_ref)]))

    if norme_texte == 0 || norme_ref == 0
        return 0.0
    end

    return produit_scalaire / (norme_texte * norme_ref)
end

"""
Analyse un fichier unique et le compare à la base de données globale.
Affiche son TTR et ses mots les plus spécifiques par rapport au corpus.
"""
function analyser_texte_inconnu(chemin_fichier::String, donnees_ref::Dict{String, Dict{String, Int}})
    println("=======================================================")
    println("ANALYSE DU FICHIER : $(basename(chemin_fichier))")

    if !isfile(chemin_fichier)
        println("Erreur : Le fichier '$chemin_fichier' n'existe pas.")
        return
    end

    # Lecture et Nettoyage
    dict_livre = process_file(chemin_fichier)
    if dict_livre === nothing
        println("Erreur : Impossible de lire le fichier.")
        return
    end

    # Calcul du TTR (Richesse)
    mots_uniques = length(dict_livre)
    mots_totaux = sum(values(dict_livre))
    ttr = (mots_uniques / mots_totaux) * 100

    println("STATISTIQUES DE STYLE :")
    println("Mots Totaux  : $mots_totaux")
    println("Mots Uniques : $mots_uniques")
    println("Richesse (TTR) : $(round(ttr, digits=4)) %")

    # CLASSIFICATION (SIMILARITÉ COSINUS)
    println("Calcul de ressemblance (Similarité Cosinus) :")
    scores_classif = Tuple{String, Float64}[]

    for (mvt, dict_ref) in donnees_ref
        score = calcul_similarite_cosinus(dict_livre, dict_ref)
        push!(scores_classif, (mvt, score))
        # On affiche le score en pourcentage pour que ce soit parlant
        println("vs $(uppercase(mvt)) \t: $(round(score * 100, digits=2)) % de similarité")
    end

    # Tri pour trouver le vainqueur
    sort!(scores_classif, by = x -> x[2], rev = true)
    gagnant = scores_classif[1][1]

    println("VERDICT LEXICAL : Le vocabulaire est le plus proche du $(uppercase(gagnant))")

    # Mots Discriminants
    # On reconstruit le dictionnaire global pour la comparaison
    dict_global = Dict{String, Int}()
    for d in values(donnees_ref)
        for (mot, count) in d
            dict_global[mot] = get(dict_global, mot, 0) + count
        end
    end
    total_global = sum(values(dict_global))

    blacklist = get_blacklist()

    scores = Tuple{String, Float64}[]

    for (mot, count) in dict_livre
        if count < 3 || mot in blacklist; continue; end # Filtre bruit

        freq_livre = count / mots_totaux
        # Compare à la fréquence globale (si le mot n'existe pas globalement, prend une fréquence minime)
        count_global = get(dict_global, mot, 1)
        freq_global = count_global / total_global

        score = freq_livre / freq_global
        push!(scores, (mot, score))
    end

    sort!(scores, by = x -> x[2], rev = true)

    println("MOTS CLÉS (SIGNATURE DU LIVRE) :")
    for i in 1:min(15, length(scores))
        mot, score = scores[i]
        println("   $i. $mot (x$(round(score, digits=1)))")
    end
    println("=======================================================")

    #return scores_classif
    probs = softmax_scores(scores_classif, 0.2)   # équilibré
    return probs
end

function softmax_scores(scores::Vector{Tuple{String, Float64}}, T::Float64)
    values = [s[2] for s in scores]

    max_val = maximum(values)
    exp_vals = exp.((values .- max_val) ./ T)
    probs = exp_vals ./ sum(exp_vals)

    return [(scores[i][1], probs[i]) for i in eachindex(scores)]
end



"""
Point d'entrée pour analyser un texte inconnu.
"""
function main_analyse_inconnu()
    mouvements = ["lumieres", "naturalisme", "romantisme"]
    fichier_mystere = "book_data/romantisme/clean_p2/Notre-Dame_de_Paris.txt"
    donnees_completes = charger_reference(mouvements)
    analyser_texte_inconnu(fichier_mystere, donnees_completes)
end

"""
Génère toutes les données nécessaires pour l'analyse.
"""
function generate_all()
    # Liste des mouvements littéraires
    mouvements = ["lumieres", "naturalisme", "romantisme"]

    # Génération des fichiers csv avec threshold 0
    generate_data_mi()

    # Génération des plots
    generate_plots_mi()

    # Lancement de l'analyse des mots discriminants
    analyser_specificite_mouvements(mouvements, 30)

    # Lancement de l'analyse de richesse
    analyser_richesse_lexicale(mouvements)

    # Vérification de la loi de Zipf
    verifier_loi_zipf()
end


### Main Execution (to comment when not in test)

# generate_all()
# main_analyse_inconnu()