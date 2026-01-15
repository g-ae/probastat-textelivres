using CSV
using DataFrames
using Glob
using StatsBase

# =============================================================================
# CHARGEMENT DES THEMES
# =============================================================================

function load_all_themes(dir::String="themes2")
    full = Dict{String, NamedTuple{(:movement, :words), Tuple{String, Vector{String}}}}()

    for movement in readdir(dir)
        mov_path = joinpath(dir, movement)
        if isdir(mov_path)
            for file in Glob.glob("*.csv", mov_path)
                theme_name = splitext(basename(file))[1]
                df = CSV.read(file, DataFrame)
                words = lowercase.(string.(df[:, 1]))
                # Filtrer les mots vides et "mot" (header)
                words = filter(w -> w != "mot" && w != "", words)
                full[theme_name] = (movement=movement, words=words)
            end
        end
    end

    return full
end

function count_words_per_movement(themes_dict)
    counts = Dict{String, Int}()
    for (theme, data) in themes_dict
        mov = data.movement
        counts[mov] = get(counts, mov, 0) + length(data.words)
    end
    return counts
end

# =============================================================================
# CHARGEMENT DU LIVRE
# =============================================================================

function load_book(path::String)
    text = read(path, String)
    words = split(lowercase(text), r"[\s\p{P}]+"; keepempty=false)
    return words
end

# =============================================================================
# ANALYSE
# =============================================================================

function analyse_book(book_words, themes_dict)
    # Comptage par thème
    theme_counts = Dict{String, Int}()
    for t in keys(themes_dict)
        theme_counts[t] = 0
    end

    # Index inversé: mot -> thèmes
    word_to_themes = Dict{String, Vector{String}}()
    for (theme, data) in themes_dict
        for w in data.words
            push!(get!(word_to_themes, w, String[]), theme)
        end
    end

    # Compter les occurrences
    for word in book_words
        if haskey(word_to_themes, word)
            for t in word_to_themes[word]
                theme_counts[t] += 1
            end
        end
    end

    return theme_counts
end

function compute_movement_scores(theme_counts, themes_dict, total_words)
    movements = ["romantisme", "naturalisme", "lumieres"]

    scores = Dict{String, NamedTuple}()

    for mov in movements
        # Thèmes de ce mouvement
        mov_themes = [t for (t, data) in themes_dict if data.movement == mov]

        # Somme brute des occurrences
        raw_count = sum(get(theme_counts, t, 0) for t in mov_themes)

        # Nombre de mots-clés dans ce mouvement
        vocab_size = sum(length(themes_dict[t].words) for t in mov_themes)

        # Score normalisé (occurrences / taille vocabulaire)
        normalized = vocab_size > 0 ? raw_count / vocab_size : 0.0

        # Densité (pour 10000 mots du livre)
        density = total_words > 0 ? (raw_count / total_words) * 10000 : 0.0

        # Nombre de thèmes actifs (au moins 5 occurrences)
        active_themes = sum(get(theme_counts, t, 0) >= 5 for t in mov_themes)

        # Score combiné
        combined = normalized * (1 + 0.2 * active_themes)

        scores[mov] = (
            raw = raw_count,
            normalized = round(normalized, digits=2),
            density = round(density, digits=2),
            active_themes = active_themes,
            combined = round(combined, digits=2)
        )
    end

    return scores
end

function predict_movement(scores)
    best_mov = ""
    best_score = -1.0

    for (mov, s) in scores
        if s.combined > best_score
            best_score = s.combined
            best_mov = mov
        end
    end

    return best_mov
end

# =============================================================================
# ANALYSE D'UN LIVRE
# =============================================================================

function analyse_one_book(movement::String, bookname::String, all_themes, results_summary)
    path_book = joinpath("book_data", movement, "clean_p2", bookname)

    if !isfile(path_book)
        println("Fichier non trouvé: $path_book")
        return
    end

    println("Analyse: $bookname")

    # Charger le livre
    book_words = load_book(path_book)
    total_words = length(book_words)

    # Analyser
    theme_counts = analyse_book(book_words, all_themes)

    # Calculer les scores par mouvement
    mov_scores = compute_movement_scores(theme_counts, all_themes, total_words)

    # Prédiction
    predicted = predict_movement(mov_scores)
    is_correct = predicted == movement

    # Construire le DataFrame de sortie
    themes = collect(keys(theme_counts))
    counts = [theme_counts[t] for t in themes]
    movements_col = [all_themes[t].movement for t in themes]

    df = DataFrame(
        theme = themes,
        mouvement = movements_col,
        count = counts
    )
    sort!(df, :count, rev=true)

    # Ajouter les scores par mouvement
    push!(df, ("___SCORES___", "---", 0))
    for mov in ["romantisme", "naturalisme", "lumieres"]
        s = mov_scores[mov]
        push!(df, ("score_raw_$mov", mov, s.raw))
        push!(df, ("score_norm_$mov", mov, round(Int, s.normalized * 100)))
        push!(df, ("score_density_$mov", mov, round(Int, s.density)))
        push!(df, ("active_themes_$mov", mov, s.active_themes))
    end
    push!(df, ("PREDICTION", predicted, is_correct ? 1 : 0))
    push!(df, ("TOTAL_WORDS", movement, total_words))

    # Sauvegarder
    out_dir = joinpath("themes_data2", movement)
    isdir(out_dir) || mkpath(out_dir)
    out_path = joinpath(out_dir, "data_$(bookname).csv")
    CSV.write(out_path, df)

    # Ajouter au résumé
    push!(results_summary, (
        livre = bookname,
        mouvement_reel = movement,
        mouvement_predit = predicted,
        correct = is_correct,
        total_words = total_words,
        score_rom = mov_scores["romantisme"].combined,
        score_nat = mov_scores["naturalisme"].combined,
        score_lum = mov_scores["lumieres"].combined
    ))

    # Affichage console
    status = is_correct ? "OK" : "X"
    println("  $status Predit: $predicted | Scores: Rom=$(mov_scores["romantisme"].combined), Nat=$(mov_scores["naturalisme"].combined), Lum=$(mov_scores["lumieres"].combined)")
end

# =============================================================================
# CREATION CSV PAR MOUVEMENT
# =============================================================================

function create_summary_per_movement(df_summary)
    println("\nCreation des fichiers de resultats par mouvement...")

    for movement in ["lumieres", "naturalisme", "romantisme"]
        # Filtrer les livres de ce mouvement
        subset = df_summary[df_summary.mouvement_reel .== movement, :]

        if nrow(subset) == 0
            continue
        end

        # Compter les prédictions
        count_rom = sum(subset.mouvement_predit .== "romantisme")
        count_nat = sum(subset.mouvement_predit .== "naturalisme")
        count_lum = sum(subset.mouvement_predit .== "lumieres")

        # Créer le DataFrame de résultat (convertir correct en String)
        result_df = DataFrame(
            livre = String.(subset.livre),
            courant_detecte = String.(subset.mouvement_predit),
            correct = [x ? "true" : "false" for x in subset.correct],
            score_rom = string.(subset.score_rom),
            score_nat = string.(subset.score_nat),
            score_lum = string.(subset.score_lum)
        )

        # Ajouter les totaux
        push!(result_df, ("___TOTAUX___", "---", "", "", "", ""))
        push!(result_df, ("TOTAL_romantisme", string(count_rom), "", "", "", ""))
        push!(result_df, ("TOTAL_naturalisme", string(count_nat), "", "", "", ""))
        push!(result_df, ("TOTAL_lumieres", string(count_lum), "", "", "", ""))

        # Précision
        n_correct = sum(subset.correct)
        n_total = nrow(subset)
        precision = round(n_correct / n_total * 100, digits=1)
        push!(result_df, ("PRECISION", "$(precision)%", "", "", "", ""))

        # Sauvegarder
        out_dir = joinpath("themes_data2", movement)
        isdir(out_dir) || mkpath(out_dir)
        out_path = joinpath(out_dir, "resultat_$(movement).csv")
        CSV.write(out_path, result_df)

        println("  -> $out_path")
    end
end

# =============================================================================
# MAIN
# =============================================================================

function main()
    println("=" ^ 60)
    println("ANALYSE THEMATIQUE DES LIVRES")
    println("=" ^ 60)

    # Charger tous les thèmes une seule fois
    println("\nChargement des themes depuis themes2/...")
    all_themes = load_all_themes("themes2")

    # Afficher les stats des thèmes
    words_per_mov = count_words_per_movement(all_themes)
    println("\nVocabulaire par mouvement:")
    for (mov, count) in words_per_mov
        println("  - $mov: $count mots-cles")
    end

    # Préparer le résumé
    results_summary = NamedTuple[]

    # Analyser tous les livres
    folders = [
        ("lumieres", "book_data/lumieres/clean_p2"),
        ("naturalisme", "book_data/naturalisme/clean_p2"),
        ("romantisme", "book_data/romantisme/clean_p2")
    ]

    for (movement, folder) in folders
        println("\n" * "-" ^ 60)
        println("MOUVEMENT: $(uppercase(movement))")
        println("-" ^ 60)

        for fullpath in Glob.glob("*.txt", folder)
            bookname = basename(fullpath)
            analyse_one_book(movement, bookname, all_themes, results_summary)
        end
    end

    # Créer le DataFrame de résumé
    if !isempty(results_summary)
        df_summary = DataFrame(results_summary)

        # Sauvegarder le résumé
        isdir("themes_data2") || mkpath("themes_data2")
        CSV.write("themes_data2/resultats_global.csv", df_summary)

        # Statistiques finales
        println("\n" * "=" ^ 60)
        println("RESUME GLOBAL")
        println("=" ^ 60)

        total = nrow(df_summary)
        correct = sum(df_summary.correct)
        accuracy = round(correct / total * 100, digits=1)

        println("\nPrecision globale: $correct / $total ($accuracy%)")

        # Précision par mouvement
        for mov in ["lumieres", "naturalisme", "romantisme"]
            subset = df_summary[df_summary.mouvement_reel .== mov, :]
            n = nrow(subset)
            c = sum(subset.correct)
            acc = n > 0 ? round(c / n * 100, digits=1) : 0.0
            println("  - $mov: $c / $n ($acc%)")
        end

        # Matrice de confusion simple
        println("\nMatrice de confusion:")
        println("  Reel \\ Predit  | Lum | Nat | Rom")
        for real_mov in ["lumieres", "naturalisme", "romantisme"]
            row = df_summary[df_summary.mouvement_reel .== real_mov, :]
            lum = sum(row.mouvement_predit .== "lumieres")
            nat = sum(row.mouvement_predit .== "naturalisme")
            rom = sum(row.mouvement_predit .== "romantisme")
            label = rpad(real_mov, 14)
            println("  $label |  $lum  |  $nat  |  $rom")
        end

        # Créer les CSV par mouvement
        create_summary_per_movement(df_summary)

        println("\n-> Resultats sauvegardes dans themes_data2/")
    end
end

# Lancer l'analyse
main()
