function longueur_phrases(text::String)
    # Renvoie un dictionnaire "nbr de mots dans la phrase" => "nbr de phrases"
    res = Dict{Int, Int}()
    phrases = split(text, r"[.!?]+")

    for phrase in phrases
        phrase = strip(phrase)
        if isempty(phrase)
            continue
        end

        words = split(phrase)
        n_words = length(words)

        if haskey(res, n_words)
            res[n_words] += 1
        else
            res[n_words] = 1
        end
    end

    return res
end

function save_longueur_phrases(phrases_dict::Dict{Int, Int}, output_file::String)
    dir = dirname(output_file)
    if !isempty(dir) && dir != "." && !isdir(dir)
        mkpath(dir)
    end

    open(output_file, "w") do f
        for (nbr_mots, nbr_phrases) in phrases_dict
            println(f, "$nbr_mots: $nbr_phrases")
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

using Plots
using StatsPlots
using Measures

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

    # bar groupé (dodge) : chaque mouvement est une série
    Plots.bar(all_keys, counts,
        bar_position = :dodge,
        labels = mouvements,
        title = "Distribution des longueurs de phrases",
        xlabel = "Longueur (mots)",
        ylabel = "Nombre de phrases",
        rotation = 45)
    savefig("longueurs_phrases/distribution_longueurs_phrases.png")
end

function plot_boxplot(mouvements::Vector{String})
    data = []

    for m in mouvements
        filename = "longueurs_phrases/" * m * "_total.txt"
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

        push!(data, longueurs)
    end

    StatsPlots.boxplot(data;
        labels = false,
        orientation = :horizontal,
        yticks = (1:length(mouvements), mouvements),
        title = "Longueurs des phrases par mouvement",
        xlabel = "Longueur des phrases (mots)",
        ylabel = "Mouvement")
    savefig("longueurs_phrases/boxplot_longueurs_phrases.png")
end

using HypothesisTests
using Statistics

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

const mouvements = ["lumieres", "naturalisme", "romantisme"]

function generer_data()
    for m in mouvements
        all_files = readdir(pwd() * "/book_data/" * m * "/clean_p1/")
        book_files = filter(f -> contains(f, '.'), all_files)

        dicts::Vector{Dict{Int, Int}} = []

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

            save_longueur_phrases(longueur_phrases(join(lines, " ")), "longueurs_phrases/" * m * "/" * file_name)

            push!(dicts, longueur_phrases(join(lines, " ")))
        end

        total_longueur = concat_longueur_dicts(dicts)
        save_longueur_phrases(total_longueur, "longueurs_phrases/" * m * "_total.txt")

        println("--------------------------------------------------")
        for m in mouvements
            avg = moyenne_longueur_mvt(m)
            med = mediane_longueur_mvt(m)
            println("Mouvement: $m - Moyenne: $avg - Médiane: $med")
            distribution = distribution_longueurs_mvt(m)
    #         println("Distribution des longueurs de phrases (en mots => nombre de phrases):")
    #         for (nbr_mots, nbr_phrases) in sort(collect(distribution))
    #             println("  $nbr_mots => $nbr_phrases")
    #         end
        end
        println("--------------------------------------------------")
    end
end

# Generate data
# generer_data()

### Plots
# plot_moyennes(mouvements)
# plot_mediane(mouvements)
# plot_distribution(mouvements)
# plot_boxplot(mouvements)

### Test statistique
println("Lancement de l'analyse statistique")
effectuer_test_anova(mouvements)