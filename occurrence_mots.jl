using Plots
using Measures

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
    blacklist = Set([
        # === 1. BRUIT ANGLAIS TRONQUÉ (STAMMED) ===
        "thi", "provid", "distribut", "includ", "stat", "damag", "us", "can",
        "electr", "foundat", "copi", "copy", "project", "gutenberg", "archiv",
        "work", "licens", "term", "agreem", "copyright", "public", "domain",
        "law", "unit", "state", "complianc", "requir", "restrict", "violat",
        "access", "liabil", "warranti", "disclaim", "limit", "indemnifi",
        "refund", "replac", "defect", "neglig", "breach", "contract", "tort",
        "merchant", "fit", "purpos", "incid", "consequ", "punit", "applic",
        "proprietari", "intellectu", "properti", "fil", "comput", "system",
        "viru", "format", "readabl", "binari", "compress", "download", "onlin",
        "network", "server", "post", "locat", "associ", "provid", "forth",
        "full", "legal", "http", "www", "org", "net", "com", "html", "txt",
        "ascii", "zip", "email", "volunt", "newslett", "donat", "chariti",
        "payment", "credit", "card", "check",
        "the", "and", "that", "with", "from", "have", "which", "you", "one",
        "all", "not", "are", "was", "but", "for", "may", "can", "very", "what",

        # === 1. VOCABULAIRE TECHNIQUE & JURIDIQUE (Licences Anglaises) ===
        # Mots courants de la licence Project Gutenberg
        "project", "gutenberg", "literary", "archive", "foundation",
        "electronic", "work", "works", "license", "terms", "agreement",
        "copyright", "domain", "public", "united", "states", "law", "laws",
        "access", "distribute", "distributed", "copy", "copies", "copying",
        "damages", "liability", "warranty", "disclaimer", "limitation", "indemnify",
        "refund", "replacement", "donation", "charity", "donations",
        "file", "files", "data", "computer", "system", "virus", "defect",
        "format", "readable", "processor", "online", "network", "posted",
        "this", "that", "with", "from", "have", "which", "form", "days",
        "about", "associated", "compliance", "country", "forth", "located",
        "http", "www", "org", "net", "com", "html", "txt", "ascii", "holder", "check",
        "proofreading", "team", "digitized", "produced", "by", "of", "and", "the", "in", "to", "or", "is", "for", # Petits mots anglais fréquents

        # === 1. DERNIERS AJOUTS  ===
        "foundation", "access", "damages", "located", # Anglais
        "cazotte",
        "compliance", "country", "distribute", "copy", "forth",
        "julielettre", "ferval", "zurich", "omphale", "gangarides",

        # === 2. BRUIT INFORMATIQUE (Mots anglais des licences Gutenberg/Archive) ===
        "this", "that", "with", "from", "have", "which", "form", "days",
        "agreement", "requirements", "posted", "associated", "about", "work",
        "works", "terms", "license", "online", "distributed", "proofreading",
        "team", "file", "http", "www", "gutenberg", "archive", "digitized",
        "project", "ebook", "ebooks", "title", "author", "language", "release",
        "fees", "may", "used", "anyone", "anywhere", "subject", "special", "permissions", "see", "details", "distribution",
        "modification", "under", "copyright", "laws", "public", "domain", "reading",
        "rights", "reserved", "donate", "contributions", "support", "online", "copyright",
        "including", "using", "other",

        # === 3. PERSONNAGES & LIEUX (Détails littéraires) ===
        # === LUMIÈRES ===
        # Voltaire (Noms uniques seulement)
        "pangloss", "cunégonde", "cacambo", "zadig", "astarté", "moabdar",
        "micromégas", "kerkabon", "formosante", "amazan", "babylone", "sirius",
        # Montesquieu
        "usbek", "rica", "roxane", "ispahan", "nadié", "zachi",
        # Prévost & Marivaux
        "lescaut", "grieux", "tiberge", "cleveland", "axminster",
        "valville", "climal", "dutour", "habert", "fécour",
        # Rousseau
        "wolmar", "saint-preux", "étampes", "clarens", "héloïse",
        # Diderot
        "simonin", "arpajon", "mirzoza", "mangogul", "zaïde", "iwan",
        # Laclos & Sade
        "merteuil", "valmont", "tourvel", "volanges", "rosemonde", "danceny",
        "blamont", "noirceuil", "saint-fond", "rodin", "sade",
        # Lesage & Autres
        "santillane", "sangrado", "asmodée", "cléofas", "zambullo",
        "alvare", "biondetta", "soberano", "télémaque", "calypso", "idoménée",
        "amanzéi", "phénime", "zulica", "meilcour", "lursay", "zilia", "aza", "déterville",
        "joannetti", "corinne", "oswald", "nelvil", "lucile", "delphine", "albemar", "léonce",
        "ellénore", "oberman",

        # === ROMANTISME ===
        # Chateaubriand
        "atala", "chactas", "celuta", "aubry",
        # Hugo (Noms distinctifs)
        "esmeralda", "quasimodo", "frollo", "gringoire", "phoebus",
        "valjean", "javert", "cosette", "marius", "gavroche", "thenardier", "fantine", "myriel",
        "ordener", "schumacker", "bug-jargal", "habibrah",
        "gilliatt", "déruchette", "lethierry", "gwynplaine", "dea", "ursus", "josiana",
        "lantenac", "gauvain", "cimourdain",
        # Dumas
        "artagnan", "athos", "porthos", "aramis", "tréville", "planchet",
        "dantes", "edmond", "monte-cristo", "faria", "mercedes", "mondego", "danglars", "villefort",
        "mordaunt", "mazarin", "raoul", "bragelonne", "fouquet", "vallière",
        "coconnas", "bussy", "monsoreau", "chicot", "balsamo",
        # Sand
        "indiana", "ralph", "raymon", "delmare", "lélia", "sténio", "trenmor",
        "consuelo", "porpora", "rudolstadt", "fadette", "landry", "sylvinet", "fanchon",
        "mauprat", "edmée",
        # Vigny, Musset, Mérimée...
        "cinq-mars", "stello", "collingwood", "sylvie", "aurélia",
        "colomba", "orso", "rebbia", "carmen", "escamillo", "maupin", "graziella", "amaury", "couaën",

        # === NATURALISME ===
        # Zola (Rougon-Macquart)
        "gervaise", "coupeau", "nana", "goujet", "lorilleux", "boche",
        "lantier", "maheu", "maheude", "chaval", "hennebeau", "souvarine", "negrel", "voreux",
        "muffat", "fontan", "satin", "roubaud", "severine", "pecqueux", "misard",
        "baudu", "mouret", "bourdoncle", "hutin", "josserand", "campardon",
        "saccard", "renée", "albine", "désirée", "florent", "quenu", "gradelle",
        "raquin", "rougon", "macquart", "silvère", "miette", "adélaïde",
        "clorinde", "sandoz", "fouan", "buteau", "gundermann",
        # Maupassant
        "lamare", "rosalie", "duroy", "forestier", "walter", "andermatt", "guilleroy", "mariolle",
        # Huysmans & Autres
        "desesseintes", "durtal", "hermies", "chantelouve", "vatard", "cyprien", "folantin",
        "germinie", "lacerteux", "jupillon", "gervaisais", "vingtras", "mintié"
    ])

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

    # Mots Discriminants
    # On reconstruit le dictionnaire global pour la comparaison
    dict_global = Dict{String, Int}()
    for d in values(donnees_ref)
        for (mot, count) in d
            dict_global[mot] = get(dict_global, mot, 0) + count
        end
    end
    total_global = sum(values(dict_global))

    blacklist = Set([
        "the", "and", "of", "to", "project", "gutenberg", "edition", "chapter",
        "this", "that", "with", "from", "julielettre", "cazotte", "persan",
        "pangloss", "cunegond", "usbek", "atala", "valjean", "gervaise", "nana"
    ])

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
end


### Main Execution (to comment when not in test)

# generate_all()
# main_analyse_inconnu()