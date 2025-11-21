function occurrence_mots(text::String)
    # Retourne un dictionnaire avec l'occurrence de chaque mot dans le texte
    res = Dict{String, Int}()
    words = split(text)

    for word in words
        word = strip(word, ['.', ',', '!', '?', ';', '"', '\'', '(', ')', '[', ']', '{', '}', '-'])
        if haskey(res, word)
            res[word] += 1
        else
            res[word] = 1
        end
    end

    return res
end

function save_occurrence_mots(occ_dict::Dict{String, Int}, output_file::String)
    dir = dirname(output_file)
    if !isempty(dir) && dir != "." && !isdir(dir)
        mkpath(dir)
    end

    open(output_file, "w") do f
        for (word, count) in occ_dict
            println(f, "$word: $count")
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

### Test
const mouvements = ["naturalisme", "romantisme"]

for m in mouvements
    all_files = readdir(pwd() * "/book_data/" * m * "/clean_p2/")
    book_files = filter(f -> contains(f, '.'), all_files)

    dicts::Vector{Dict{String, Int}} = []

    for (i, file_name) in enumerate(book_files)
        println(m * "/clean_p2/" * file_name * " (" * string(i) * "/" * string(length(book_files)) * ")")

        # Ouvrir fichier pour récupérer son contenu
        lines = []
        open(pwd() * "/book_data/" * m * "/clean_p2/" * file_name) do f
            lines = readlines(f)
        end

        if length(lines) == 0
            continue
        end

        push!(dicts, occurrence_mots(join(lines, " ")))
    end

    total_occ = concat_occurrence_dicts(dicts)
    save_occurrence_mots(total_occ, "occurrences_mots/" * m * "_total.txt")
end
