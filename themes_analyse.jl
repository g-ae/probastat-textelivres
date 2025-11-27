using CSV
using DataFrames
using Glob
using StatsBase

function load_all_themes(dir::String="themes")

    full = Dict{String, NamedTuple{(:movement, :words), Tuple{String, Vector{String}}}}()

    for movement in readdir(dir)
        mov_path = joinpath(dir, movement)
        if isdir(mov_path)
            for file in Glob.glob("*.csv", mov_path)
                theme_name = splitext(basename(file))[1]
                df = CSV.read(file, DataFrame; delim=';')
                words = lowercase.(df[:, 1])
                full[theme_name] = (movement=movement, words=words)
            end
        end
    end

    return full
end

function load_book(path::String)
    lines = readlines(path)
    tokenized = [split(lowercase(line)) for line in lines if !isempty(line)]
    return tokenized
end

function analyse_book(book, themes_dict)

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

    for sentence in book
        for word in sentence
            if haskey(word_to_themes, word)
                for t in word_to_themes[word]
                    theme_counts[t] += 1
                end
            end
        end
    end

    return theme_counts
end

function analyse_one_book(movement::String, bookname::String)

    println("Chargement de tous les thèmes…")
    all_themes = load_all_themes()

    path_book = joinpath("book_data", movement, "clean_p2", bookname)
    println("Chargement du livre : $path_book")

    book = load_book(path_book)

    println("Analyse…")
    theme_counts = analyse_book(book, all_themes)

    out_dir = joinpath("themes_data", movement)
    isdir(out_dir) || mkpath(out_dir)

    out_path = joinpath(out_dir, "data_$(bookname).csv")

    themes = collect(keys(theme_counts))
    counts = collect(values(theme_counts))
    movements = [all_themes[t].movement for t in themes]

    df = DataFrame(
        theme = themes,
        mouvement = movements,
        count = counts
    )

    total_romantisme = sum(df.count[df.mouvement .== "romantisme"])
    total_naturalisme = sum(df.count[df.mouvement .== "naturalisme"])
    total_lumieres = sum(df.count[df.mouvement .== "lumieres"])

    push!(df, ("TOTAL_romantisme", "romantisme", total_romantisme))
    push!(df, ("TOTAL_naturalisme", "naturalisme", total_naturalisme))
    push!(df, ("TOTAL_lumieres", "lumieres", total_lumieres))

    CSV.write(out_path, df)

    println("\n=== Analyse terminée ===")
    println("→ Résultats enregistrés dans : $out_path\n")
end

#appel ---------------------------------------------

folder = "book_data/romantisme/clean_p2"

for fullpath in Glob.glob("*.txt", folder)
    bookname = basename(fullpath)
    analyse_one_book("romantisme", bookname)
end