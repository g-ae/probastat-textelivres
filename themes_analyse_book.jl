using CSV
using DataFrames
using Glob

function load_all_themes(dir::String="themes2")
    full = Dict{String, NamedTuple{(:movement, :words), Tuple{String, Vector{String}}}}()

    for movement in readdir(dir)
        mov_path = joinpath(dir, movement)
        if isdir(mov_path)
            for file in Glob.glob("*.csv", mov_path)
                theme_name = splitext(basename(file))[1]
                df = CSV.read(file, DataFrame)
                words = lowercase.(string.(df[:, 1]))
                words = filter(w -> w != "mot" && w != "", words)
                full[theme_name] = (movement=movement, words=words)
            end
        end
    end

    return full
end

function load_book(path::String)
    text = read(path, String)
    words = split(lowercase(text), r"[\s\p{P}]+"; keepempty=false)
    return words
end

function analyse_book(book_words, themes_dict)
    theme_counts = Dict{String, Int}()
    for t in keys(themes_dict)
        theme_counts[t] = 0
    end

    word_to_themes = Dict{String, Vector{String}}()
    for (theme, data) in themes_dict
        for w in data.words
            push!(get!(word_to_themes, w, String[]), theme)
        end
    end

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
    scores = Dict{String, Float64}()

    for mov in movements
        mov_themes = [t for (t, data) in themes_dict if data.movement == mov]
        raw_count = sum(get(theme_counts, t, 0) for t in mov_themes)
        vocab_size = sum(length(themes_dict[t].words) for t in mov_themes)
        normalized = vocab_size > 0 ? raw_count / vocab_size : 0.0
        active_themes = sum(get(theme_counts, t, 0) >= 5 for t in mov_themes)
        combined = normalized * (1 + 0.2 * active_themes)
        scores[mov] = round(combined, digits=2)
    end

    return scores
end

# Cache pour les themes (charge une seule fois)
const THEMES_CACHE = Ref{Union{Nothing, Dict}}(nothing)

function get_themes()
    if THEMES_CACHE[] === nothing
        THEMES_CACHE[] = load_all_themes("themes2")
    end
    return THEMES_CACHE[]
end

"""
    analyse_themes(book_path::String) -> (Float64, Float64, Float64)

Analyse un livre et retourne les scores (romantisme, naturalisme, lumieres).
"""
function analyse_themes(book_path::String)
    all_themes = get_themes()
    book_words = load_book(book_path)
    total_words = length(book_words)
    theme_counts = analyse_book(book_words, all_themes)
    scores = compute_movement_scores(theme_counts, all_themes, total_words)

    return scores
end


#print(analyse_themes("/Users/filippo/Desktop/ISC2/sem 1/prob et stats/projet/probastat-textelivres/book_data/romantisme/clean_p2/Han_d’Islande.txt"))