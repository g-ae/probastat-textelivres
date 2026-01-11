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
             xlims=(0, 80),
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

generate_all()
