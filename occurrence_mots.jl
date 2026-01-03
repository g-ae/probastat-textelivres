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

    # --- Total words ---
    total_words = sum(values(occ_dict))
    unique_words = length(occ_dict)
    println("--- Stats for $mouvement ---")
    println("Total words: $total_words")
    println("Unique words: $unique_words")

    # Total words bar
    bar([mouvement], [total_words];
        color = :blue,
        title = "Total de mots — $mouvement",
        xlabel = "Mouvement", ylabel = "Nombre de mots",
        legend = false
    )
    annotate!(1, total_words + total_words*0.02, text(string(total_words), :center, 10))
    savefig(dir * "total_words_" * mouvement * ".png")
    println("Saved: $(dir)total_words_$mouvement.png")

    # Unique words bar
    bar([mouvement], [unique_words];
        color = :green,
        title = "Mots uniques — $mouvement",
        xlabel = "Mouvement", ylabel = "Nombre de mots",
        legend = false
    )
    annotate!(1, unique_words + unique_words*0.02, text(string(unique_words), :center, 10))
    savefig(dir * "unique_words_" * mouvement * ".png")
    println("Saved: $(dir)unique_words_$mouvement.png")

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

using Plots
using Measures

### Test process
const mouvements = ["lumieres", "naturalisme", "romantisme"]
# const threshold = 5
# all_occ_dicts::Vector{Dict{String, Int64}} = []
# for m in mouvements
#     occ_mvt = process_mouvement(m, threshold)
#     push!(all_occ_dicts, occ_mvt)
#     #plot_word_stats(occ_mvt, m; top_n=10)
# end
# plot_total_and_unique_separately(all_occ_dicts, mouvements)
# for (i, m) in enumerate(mouvements)
#     plot_stats_for_movement(all_occ_dicts[i], m; top_n=10)
# end


# Analyse de Spécificité (TF-IDF simplifié)
"""
Cette fonction compare les vocabulaires pour trouver les mots-clés typiques.
Elle calcule un ratio : (Fréquence dans le mouvement) / (Fréquence globale).
Si le ratio > 1, le mot est sur-représenté.
"""
function analyser_specificite_mouvements(mouvements::Vector{String}, seuil_frequence::Int=50)
    println("\n--- ANALYSE DES MOTS DISCRIMINANTS (SPÉCIFICITÉ) ---")

    # Charger tous les dictionnaires
    dicts_par_mvt = Dict{String, Dict{String, Int}}()
    total_mots_par_mvt = Dict{String, Int}()

    # Dictionnaire global
    dict_global = Dict{String, Int}()
    total_mots_global = 0

    for m in mouvements
        path = "occurrences_mots/" * m * "_total.csv"

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
        println("\n--- TOP 20 MOTS TYPIQUES : $(uppercase(m)) ---")

        for i in 1:min(20, length(scores))
            mot, score = scores[i]
            println("  $i. $mot (x$(round(score, digits=1)))")
        end
    end
    println("======================================================\n")
end

"""
Calcule le Type-Token Ratio (TTR).
TTR = (Nombre de mots uniques) / (Nombre total de mots).
Un TTR élevé indique un vocabulaire riche et varié.
"""
function analyser_richesse_lexicale(mouvements::Vector{String})
    println("\n--- ANALYSE DE LA RICHESSE LEXICALE (TTR) ---")
    println("Calcul du ratio : (Mots Uniques / Mots Totaux) * 100")

    for m in mouvements
        filename = "occurrences_mots/" * m * "_total.csv"

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

        println("\n--- Mouvement : $(uppercase(m)) ---")
        println("Mots Totaux  : $mots_totaux")
        println("Mots Uniques : $mots_uniques")
        println("Score TTR    : $(round(ttr, digits=2)) %")
    end
    println("============================================\n")
end

# Lancement de l'analyse des mots discriminants
analyser_specificite_mouvements(mouvements, 30)

# Lancement de l'analyse de richesse
analyser_richesse_lexicale(mouvements)