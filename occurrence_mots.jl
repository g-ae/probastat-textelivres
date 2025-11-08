function occurrence_mots(text::String)
    res = Dict{String, Int}()
    words = split(text)

    for word in words
        word = strip(word, ['.', ',', '!', '?', ';', '"', '\'', '(', ')', '[', ']', '{', '}'])
        if haskey(res, word)
            res[word] += 1
        else
            res[word] = 1
        end
    end

    #println(res)
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

#occurrence_mots("Bonjour, bonjour! C'est un test. Un test, c'est tout.")