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
        println(f, "mot; occurrence")
        for (word, count) in occ_dict
            println(f, "$word; $count")
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

    min_occ = minimum(values(occ_dict))
    return min_occ
end

function find_max_occurrence(occ_dict::Dict{String, Int})
    if isempty(occ_dict)
        return 0
    end

    max_occ = maximum(values(occ_dict))
    return max_occ
end

function nb_mots_par_occurrence(occ_dict::Dict{String, Int}, occurrence::Int)
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
        res[occ] = nb_mots_par_occurrence(occ_dict, occ)
    end

    return res
end

test = nb_mots_par_occurrence(occurrence_mots("Ceci est un test. Ceci est seulement un test."))
println(test)

# ### Test
# const mouvements = ["lumieres", "naturalisme", "romantisme"]
#
# for m in mouvements
#     all_files = readdir(pwd() * "/book_data/" * m * "/clean_p2/")
#     book_files = filter(f -> contains(f, '.'), all_files)
#
#     dicts::Vector{Dict{String, Int}} = []
#
#     for (i, file_name) in enumerate(book_files)
#         println(m * "/clean_p2/" * file_name * " (" * string(i) * "/" * string(length(book_files)) * ")")
#
#         # Ouvrir fichier pour récupérer son contenu
#         lines = []
#         open(pwd() * "/book_data/" * m * "/clean_p2/" * file_name) do f
#             lines = readlines(f)
#         end
#
#         if length(lines) == 0
#             continue
#         end
#
#         save_occurrence_mots(occurrence_mots(join(lines, " ")), "occurrences_mots/" * m * "/" * splitext(file_name)[1] * ".csv")
#
#         push!(dicts, occurrence_mots(join(lines, " ")))
#     end
#
#     total_occ = concat_occurrence_dicts(dicts)
#     save_occurrence_mots(total_occ, "occurrences_mots/" * m * "_total.csv")
# end
