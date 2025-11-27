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
        res[occ] = nb_mots_par_occurrence(occ_dict, occ)
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
end


### Test process
const mouvements = ["lumieres", "naturalisme", "romantisme"]
const threshold = 5
for m in mouvements
    process_mouvement(m, threshold)
end
