using Plots
using StatsPlots
using Measures
using HypothesisTests
using Statistics

function longueur_phrases(text::String)
    longueurs = Int[]

    text = replace(text, "\r\n" => " ")
    text = replace(text, "\n" => " ")
    text = replace(text, r"\s+" => " ")

    phrases = split(text, r"(?<=[.!?])\s+(?=[A-ZÀ-É])")

    for phrase in phrases
        phrase = strip(phrase)
        if isempty(phrase)
            continue
        end

        words = split(phrase)
        n_words = length(words)

        if n_words >= 3
            push!(longueurs, n_words)
        end
    end

    return longueurs
end

function save_longueur_phrases(longueurs::Vector{Int}, output_file::String)
    dir = dirname(output_file)
    if !isempty(dir) && dir != "." && !isdir(dir)
        mkpath(dir)
    end

    # Conversion en dictionnaire
    phrases_dict = Dict{Int, Int}()
    for l in longueurs
        if haskey(phrases_dict, l)
            phrases_dict[l] += 1
        else
            phrases_dict[l] = 1
        end
    end

    open(output_file, "w") do f
        # Tri par longueur croissante
        for l in sort(collect(keys(phrases_dict)))
            println(f, "$l: $(phrases_dict[l])")
        end
    end
end

function concat_longueur_dicts(dicts::Vector{Dict{Int, Int}})
    res = Dict{Int, Int}()

    for dict in dicts
        for (nbr_mots, nbr_phrases) in dict
            if haskey(res, nbr_mots)
                res[nbr_mots] += nbr_phrases
            else
                res[nbr_mots] = nbr_phrases
            end
        end
    end

    return res
end

function moyenne_longueur_file(filename::String)
    total_phrases = 0.0
    total_mots = 0.0

    open(filename, "r") do f
        for line in eachline(f)
            parts = split(line, ":")
            if length(parts) == 2
                nbr_mots = parse(Int, strip(parts[1]))
                nbr_phrases = parse(Int, strip(parts[2]))

                total_phrases += nbr_phrases
                total_mots += nbr_mots * nbr_phrases
            end
        end
    end

    if total_phrases == 0
        return 0.0
    else
        return total_mots / total_phrases
    end
end

function moyenne_longueur_mvt(mvt::String)
    filename = "longueurs_phrases/" * mvt * "_total.txt"
    return moyenne_longueur_file(filename)
end

function mediane_longueur_file(filename::String)
    longueurs = Int[]

    open(filename, "r") do f
        for line in eachline(f)
            parts = split(line, ":")
            if length(parts) == 2
                nbr_mots = parse(Int, strip(parts[1]))
                nbr_phrases = parse(Int, strip(parts[2]))

                for _ in 1:nbr_phrases
                    push!(longueurs, nbr_mots)
                end
            end
        end
    end

    if isempty(longueurs)
        return 0.0
    else
        sorted_longueurs = sort(longueurs)
        n = length(sorted_longueurs)
        if isodd(n)
            return sorted_longueurs[(n + 1) ÷ 2]
        else
            return (sorted_longueurs[n ÷ 2] + sorted_longueurs[(n ÷ 2) + 1]) / 2
        end
    end
end

function mediane_longueur_mvt(mvt::String)
    filename = "longueurs_phrases/" * mvt * "_total.txt"
    return mediane_longueur_file(filename)
end

function distribution_longueurs_mvt(mvt::String)
    filename = "longueurs_phrases/" * mvt * "_total.txt"
    longueurs = Dict{Int, Int}()

    open(filename, "r") do f
        for line in eachline(f)
            parts = split(line, ":")
            if length(parts) == 2
                nbr_mots = parse(Int, strip(parts[1]))
                nbr_phrases = parse(Int, strip(parts[2]))
                longueurs[nbr_mots] = nbr_phrases
            end
        end
    end

    return longueurs
end

function plot_moyennes(mouvements::Vector{String})
    moyennes = [moyenne_longueur_mvt(m) for m in mouvements]
    palette = [:blue, :green, :red]
    colors = [palette[(i - 1) % length(palette) + 1] for i in 1:length(mouvements)]

    Plots.bar(mouvements, moyennes;
        color = colors,
        title = "Moyenne de la longueur des phrases par mouvement",
        xlabel = "Mouvement", ylabel = "Longueur moyenne (mots)", legend = false,
        top_margin = 10mm, bottom_margin = 6mm, left_margin = 6mm, right_margin = 4mm)

    maxv = isempty(moyennes) ? 0.0 : maximum(moyennes)
    offset = maxv == 0.0 ? 0.5 : maxv * 0.03

    for (i, v) in enumerate(moyennes)
        annotate!(i, v + offset, text(string(round(v, digits = 2)), :center, 8))
    end

    savefig("longueurs_phrases/moyenne_longueurs_phrases.png")
end

function plot_mediane(mouvements::Vector{String})
    medianes = [mediane_longueur_mvt(m) for m in mouvements]
    palette = [:blue, :green, :red]
    colors = [palette[(i - 1) % length(palette) + 1] for i in 1:length(mouvements)]

    Plots.bar(mouvements, medianes;
        color = colors,
        title = "Médiane de la longueur des phrases par mouvement",
        xlabel = "Mouvement", ylabel = "Médiane (mots)", legend = false,
        top_margin = 10mm, bottom_margin = 6mm, left_margin = 6mm, right_margin = 4mm)

    maxv = isempty(medianes) ? 0.0 : maximum(medianes)
    offset = maxv == 0.0 ? 0.5 : maxv * 0.02

    for (i, v) in enumerate(medianes)
        annotate!(i, v + offset, text(string(round(v, digits = 2)), :center, 8))
    end

    savefig("longueurs_phrases/mediane_longueurs_phrases.png")
end

function plot_distribution(mouvements::Vector{String})
    colors = Dict("lumieres" => :blue, "naturalisme" => :green, "romantisme" => :red)

    for m in mouvements
        dist = distribution_longueurs_mvt(m)

        longueurs = sort(collect(keys(dist)))
        comptes = [dist[l] for l in longueurs]

        # On ne garde que les phrases <= 80 mots pour le graphique.
        mask = longueurs .<= 150
        x_val = longueurs[mask]
        y_val = comptes[mask]

        p = Plots.bar(x_val, y_val,
            title = "Distribution : $(uppercase(m))",
            xlabel = "Nombre de mots par phrase",
            ylabel = "Nombre de phrases (Volume)",
            legend = false,
            color = colors[m],
            linecolor = :match, # Couleur du contour identique
            size = (600, 400)   # Taille de l'image
        )

        filename = "longueurs_phrases/distribution_$(m).png"
        savefig(p, filename)
    end
end

function plot_distribution_global(mouvements::Vector{String})
    dists = [distribution_longueurs_mvt(m) for m in mouvements]

    # union triée des longueurs présentes
    all_keys = sort(unique(vcat([collect(keys(d)) for d in dists]...)))

    # matrice: une colonne par mouvement, une ligne par longueur
    counts = zeros(Int, length(all_keys), length(mouvements))
    for (j, d) in enumerate(dists)
        for (i, k) in enumerate(all_keys)
            counts[i, j] = get(d, k, 0)
        end
    end

    # bar groupé: chaque mouvement est une série
    Plots.bar(all_keys, counts,
        bar_position = :dodge,
        labels = false,
        title = "Distribution des longueurs de phrases",
        xlabel = "Longueur (mots)",
        ylabel = "Nombre de phrases",
        rotation = 45)
    savefig("longueurs_phrases/distribution_longueurs_phrases.png")
end

function plot_distribution_densite(donnees::Dict{String, Vector{Int}}, mouvements::Vector{String})
    # xlims=(0, 80) : On zoome sur les phrases de 0 à 80 mots (99% des données)
    # pour éviter que les phrases géantes n'écrasent tout le graphique.
    p = plot(title="Distribution des longueurs de phrases",
             xlabel="Nombre de mots", ylabel="Fréquence (Densité)",
             xlims=(0, 150),
             legend=:topright)

    colors = Dict("lumieres" => :blue, "naturalisme" => :green, "romantisme" => :red)

    for m in mouvements
        if !haskey(donnees, m); continue; end
        vals = donnees[m]

        # Il trace la courbe de probabilité lissée.
        StatsPlots.density!(vals, label=uppercase(m), color=colors[m], linewidth=3, fill=(0, 0.2))
    end

    output_path = "longueurs_phrases/distribution_densite.png"
    savefig(p, output_path)
end

function plot_boxplot(mouvements::Vector{String}, donnees)
    x_data = String[]
    y_data = Int[]

    for m in mouvements
        if !haskey(donnees, m); continue; end

        vals = donnees[m]
        vals_plot = filter(v -> v <= 100, vals)

        append!(x_data, fill(uppercase(m), length(vals_plot)))
        append!(y_data, vals_plot)
    end

    p = boxplot(x_data, y_data,
        title = "Longueurs des phrases par mouvement",
        ylabel = "Mots par phrase",
        legend = false,
        outliers = false,
        color = [:blue :green :red],
        fillalpha = 0.5,
        linewidth = 2
    )

    if !isdir("longueurs_phrases"); mkpath("longueurs_phrases"); end
    savefig(p, "longueurs_phrases/boxplot_longueurs_phrases.png")
end

function generate_plots_mi(donnees::Dict{String, Vector{Int}})
    mouvements = ["lumieres", "naturalisme", "romantisme"]
    plot_moyennes(mouvements)
    plot_mediane(mouvements)
    plot_distribution(mouvements)
    plot_distribution_global(mouvements)
    plot_distribution_densite(donnees, mouvements)
    plot_boxplot(mouvements, donnees)
end

# Fonction pour récupérer les données brutes
function charger_longueurs_brutes(mvt::String)
    filename = "longueurs_phrases/" * mvt * "_total.txt"
    longueurs = Int[]

    if !isfile(filename)
        println("Attention : fichier $filename introuvable.")
        return longueurs
    end

    open(filename, "r") do f
        for line in eachline(f)
            parts = split(line, ":")
            if length(parts) == 2
                nbr_mots = parse(Int, strip(parts[1]))
                nbr_phrases = parse(Int, strip(parts[2]))

                # On "décompresse" les données : si on a "10 mots: 3 phrases",
                # on ajoute [10, 10, 10] à la liste.
                for _ in 1:nbr_phrases
                    push!(longueurs, nbr_mots)
                end
            end
        end
    end
    return longueurs
end

# ANOVA
function effectuer_test_anova(mouvements::Vector{String})
    println("TEST ANOVA")

    # Charger les données pour chaque mouvement
    groupes = []
    for m in mouvements
        data = charger_longueurs_brutes(m)
        push!(groupes, data)
        println("Mouvement $m : $(length(data)) phrases analysées.")
    end

    if any(isempty.(groupes))
        println("Erreur : Un des mouvements est vide.")
        return
    end

    # ANOVA
    test = OneWayANOVATest(groupes...)

    # Affichage et interprétation
    println("Résultat brut du test :")
    println(test)

    valeur_p = pvalue(test)
    println("P-value : $valeur_p")

    println("--- INTERPRÉTATION ---")
    if valeur_p < 0.05
        println("RÉSULTAT SIGNIFICATIF (p < 0.05)")
        println("Il y a une différence statistiquement avérée entre la longueur des phrases de ces mouvements littéraires.")
        println("La probabilité que cette différence soit due au hasard est faible.")
    else
        println("RÉSULTAT NON SIGNIFICATIF")
        println("On ne peut pas affirmer que les mouvements sont différents.")
    end
    println("========================================")
end

"""
Calcule le score ARI (Automated Readability Index).
Plus le score est élevé, plus le texte est complexe.
"""
function calcul_ari(text::String, nb_phrases::Int)
    # Nettoyage basique pour compter les caractères réels (sans espaces)
    text_clean = replace(text, r"\s+" => "")
    nb_caracteres = length(text_clean)

    # On compte les mots (approximation par l'espace)
    nb_mots = length(split(text))

    if nb_mots == 0 || nb_phrases == 0
        return 0.0
    end

    # Formule ARI
    avg_char_per_word = nb_caracteres / nb_mots
    avg_word_per_sentence = nb_mots / nb_phrases

    score = 4.71 * avg_char_per_word + 0.5 * avg_word_per_sentence - 21.43
    return score
end

function generate_data_mi()
    mouvements = ["lumieres", "naturalisme", "romantisme"]

    global_data = Dict{String, Vector{Int}}()
    stats_csv = []
    scores_ari = []

    for m in mouvements
        all_files = readdir(pwd() * "/book_data/" * m * "/clean_p1/")
        book_files = filter(f -> endswith(f, ".txt"), all_files)

        total_longueurs_mvt = Int[]

        total_ari_mvt = 0.0
        count_files = 0

        for (i, file_name) in enumerate(book_files)
            println(m * "/clean_p1/" * file_name * " (" * string(i) * "/" * string(length(book_files)) * ")")

            # Ouvrir fichier pour récupérer son contenu
            lines = []
            open(pwd() * "/book_data/" * m * "/clean_p1/" * file_name) do f
                lines = readlines(f)
            end

            if length(lines) == 0
                continue
            end

            longueurs_livre = longueur_phrases(join(lines, " "))
            save_longueur_phrases(longueurs_livre, "longueurs_phrases/" * m * "/" * file_name)
            append!(total_longueurs_mvt, longueurs_livre)

            nb_phrases_livre = length(longueurs_livre)
            if nb_phrases_livre > 0
                ari_livre = calcul_ari(join(lines, " "), nb_phrases_livre)
                total_ari_mvt += ari_livre
                count_files += 1
            end
        end

        save_longueur_phrases(total_longueurs_mvt, "longueurs_phrases/" * m * "_total.txt")

        # Stockage pour les graphiques
        global_data[m] = total_longueurs_mvt

#         println("================================================")
#         for m in mouvements
#             avg = moyenne_longueur_mvt(m)
#             med = mediane_longueur_mvt(m)
#             println("Mouvement: $m - Moyenne: $avg - Médiane: $med")
#             distribution = distribution_longueurs_mvt(m)
#     #         println("Distribution des longueurs de phrases (en mots => nombre de phrases):")
#     #         for (nbr_mots, nbr_phrases) in sort(collect(distribution))
#     #             println("  $nbr_mots => $nbr_phrases")
#     #         end
#         end
        # Calcul des stats
        if !isempty(total_longueurs_mvt)
            moy = mean(total_longueurs_mvt)
            med = median(total_longueurs_mvt)
            ecart = std(total_longueurs_mvt)
            max_len = maximum(total_longueurs_mvt)

            ari_moyen = count_files > 0 ? total_ari_mvt / count_files : 0.0

            println("================================================")
            println("STATS : $m")
            println("Moyenne : $(round(moy, digits=2))")
            println("Médiane : $(round(med, digits=2))")
            println("Écart-Type : $(round(ecart, digits=2))")
            println("Complexité (ARI moyen) : $(round(ari_moyen, digits=2))")
            println("================================================")

            push!(stats_csv, (m, moy, med, ecart, ari_moyen))
        end
    end

    # Save in CSV
    save_stats_csv(stats_csv)

    return global_data
end

function save_stats_csv(stats)
    output_file = "longueurs_phrases/stats_longueurs_phrases.csv"
    dir = dirname(output_file)
    if !isempty(dir) && dir != "." && !isdir(dir)
        mkpath(dir)
    end

    open(output_file, "w") do f
        println(f, "mouvement;moyenne;mediane;ecart_type;ari_moyen")
        for (m, moy, med, ecart, ari) in stats
            println(f, "$m;$(round(moy, digits=2));$(round(med, digits=2));$(round(ecart, digits=2));$(round(ari, digits=2))")
        end
    end

    println("Statistiques sauvegardées dans $output_file")
end

"""
Calcule la distance de Kolmogorov-Smirnov (KS) entre deux échantillons.
Mesure à quel point les deux distributions se ressemblent (0 = identique, 1 = différent).
"""
function calcul_distance_ks(data1::Vector{Int}, data2::Vector{Int})
    if isempty(data1) || isempty(data2); return 1.0; end

    # On trie les données
    s1 = sort(data1)
    s2 = sort(data2)

    n1 = length(s1)
    n2 = length(s2)

    # On parcourt les deux courbes cumulées (ECDF) pour trouver l'écart max
    i = 1; j = 1
    max_diff = 0.0

    while i <= n1 && j <= n2
        v1 = s1[i]
        v2 = s2[j]

        # Proportions actuelles (Hauteur sur la courbe cumulée)
        p1 = i / n1
        p2 = j / n2

        diff = abs(p1 - p2)
        if diff > max_diff; max_diff = diff; end

        if v1 < v2
            i += 1
        elseif v2 < v1
            j += 1
        else
            i += 1; j += 1
        end
    end

    return max_diff
end

"""
Charge les données brutes (listes de longueurs) pour comparer les distributions.
"""
function charger_donnees_brutes_ref(mouvements::Vector{String})
    refs_brutes = Dict{String, Vector{Int}}()

    for m in mouvements
        # On lit le fichier histogramme
        path = "longueurs_phrases/" * m * "_total.txt"
        if !isfile(path); continue; end

        data = Int[]
        open(path, "r") do f
            for line in eachline(f)
                parts = split(line, ":")
                if length(parts) == 2
                    len = parse(Int, strip(parts[1]))
                    count = parse(Int, strip(parts[2]))
                    # On "décompresse" : si longueur 10 apparaît 3 fois, on ajoute [10, 10, 10]
                    append!(data, fill(len, count))
                end
            end
        end
        refs_brutes[m] = data
    end
    return refs_brutes
end

"""
Charge les statistiques de référence depuis le CSV.
"""
function charger_stats_reference()
    refs = Dict{String, Tuple{Float64, Float64, Float64, Float64}}()
    path = "longueurs_phrases/stats_longueurs_phrases.csv"

    if !isfile(path)
        println("Fichier stats manquant. Lancez generate_all() d'abord.")
        return refs
    end

    open(path, "r") do f
        for line in eachline(f)
            if startswith(line, "mouvement"); continue; end
            parts = split(line, ";")
            if length(parts) >= 5
                mvt = String(parts[1])
                moy = parse(Float64, parts[2]) # Colonne 2 : Moyenne
                med = parse(Float64, parts[3]) # Colonne 3 : Médiane
                ecart = parse(Float64, parts[4]) # Colonne 4 : Écart-Type
                ari = parse(Float64, parts[5]) # Colonne 5 : ARI
                refs[mvt] = (moy, med, ecart, ari)
            end
        end
    end
    return refs
end

"""
Analyse un fichier inconnu et le compare aux références
en utilisant une distance multidimensionnelle (4 critères).
"""
function analyser_texte_inconnu_syntaxe(filepath::String)
    println("=======================================================")
    println("ANALYSE DU FICHIER : $(basename(filepath))")

    if !isfile(filepath); println("Fichier introuvable."); return; end

    # Analyse du fichier
    lines = []; open(filepath) do f; lines = readlines(f); end
    texte = join(lines, " ")
    longueurs = longueur_phrases(texte)

    if isempty(longueurs); println("Fichier vide."); return; end

    # Calculs
    my_moy = mean(longueurs)
    my_med = median(longueurs)
    my_ecart = std(longueurs)
    my_ari = calcul_ari(texte, length(longueurs))

    println("Signature du texte mystère :")
    println("   1. Moyenne    : $(round(my_moy, digits=2)) mots")
    println("   2. Médiane    : $(round(my_med, digits=2)) mots")
    println("   3. Écart-Type : $(round(my_ecart, digits=2))")
    println("   4. Complexité (ARI) : $(round(my_ari, digits=2))")

    # Chargement des Références
    refs_stats = charger_stats_reference()
    refs_brutes = charger_donnees_brutes_ref(["lumieres", "naturalisme", "romantisme"])

    if isempty(refs_stats); return; end

    println("Comparaison (Score le plus bas = Meilleur match) :")
    scores = Tuple{String, Float64}[]

    for (mvt, (ref_moy, ref_med, ref_ecart, ref_ari)) in refs_stats
        # Distance Scalaire (Somme des écarts standardisés)
        dist_scal = abs(my_moy - ref_moy) + abs(my_med - ref_med) + abs(my_ecart - ref_ecart) + abs(my_ari - ref_ari)

        # Distance de Distribution (KS) - Valeur entre 0 et 1
        # On multiplie par 20 pour qu'elle ait un poids comparable aux autres critères
        dist_ks = 1.0
        if haskey(refs_brutes, mvt)
            dist_ks = calcul_distance_ks(longueurs, refs_brutes[mvt])
        end
        poids_ks = dist_ks * 20.0

        score_total = dist_scal + poids_ks
        push!(scores, (mvt, score_total))

        print("vs $(uppercase(mvt)) \t: Score = $(round(score_total, digits=2))")
        println(" (Dist.KS: $(round(dist_ks, digits=3)) | Diff.Scalaire: $(round(dist_scal, digits=1)))")
    end

    sort!(scores, by = x -> x[2])
    gagnant = scores[1][1]
    ks_gagnant = 0.0
    if haskey(refs_brutes, gagnant); ks_gagnant = calcul_distance_ks(longueurs, refs_brutes[gagnant]); end

    println("VERDICT : Le style est $(uppercase(gagnant))")
    println("   (La distribution des phrases correspond à $(round((1-ks_gagnant)*100, digits=1))%)")
    println("=======================================================")
end


"""
Point d'entrée pour analyser un texte inconnu.
"""
function main_analyse_inconnu()
    mouvements = ["lumieres", "naturalisme", "romantisme"]
    fichier_mystere = "book_data/romantisme/clean_p1/Notre-Dame_de_Paris.txt"
    analyser_texte_inconnu_syntaxe(fichier_mystere)
end

"""
Génère toutes les données et les graphiques associés à l'analyse des longueurs de phrases.
"""
function generate_all()
    mouvements = ["lumieres", "naturalisme", "romantisme"]

    # Génération des données
    donnees = generate_data_mi()

    # Génération des graphiques
    generate_plots_mi(donnees)

    # Test statistique
    effectuer_test_anova(mouvements)
end


### Main Execution (to comment when not in test)

# generate_all()
main_analyse_inconnu()