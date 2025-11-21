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

### Test
const mouvements = ["naturalisme", "romantisme"]

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

        push!(dicts, longueur_phrases(join(lines, " ")))
    end

    total_longueur = concat_longueur_dicts(dicts)
    save_longueur_phrases(total_longueur, "longueurs_phrases/" * m * "_total.txt")
end
