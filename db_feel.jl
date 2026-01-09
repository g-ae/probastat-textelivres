using CSV, DataFrames

include("occurrence_mots.jl")

path = pwd() * "/FEEL.csv"
csv_data = DataFrame(CSV.File(path, delim=';'))

# Optimisation: Prétraiter les données CSV dans un dictionnaire pour un accès rapide
const feel_lexicon = Dict(
    row.word => (
        joy=row.joy,
        fear=row.fear,
        sadness=row.sadness,
        anger=row.anger,
        surprise=row.surprise,
        disgust=row.disgust
    ) for row in eachrow(csv_data)
)

function analyse_feel(lines_livre)
    sentiments = Dict(
        "joy" => 0.0,
        "fear" => 0.0,
        "sadness" => 0.0,
        "anger" => 0.0,
        "surprise" => 0.0,
        "disgust" => 0.0
    )

    for line in lines_livre
        for mot in split(lowercase(line), r"[^\p{L}\']+")
            if !isempty(mot)
                # On cherche le mot dans le dictionnaire pré-traité
                if haskey(feel_lexicon, mot)
                    word_scores = feel_lexicon[mot]
                    sentiments["joy"] += word_scores.joy
                    sentiments["fear"] += word_scores.fear
                    sentiments["sadness"] += word_scores.sadness
                    sentiments["anger"] += word_scores.anger
                    sentiments["surprise"] += word_scores.surprise
                    sentiments["disgust"] += word_scores.disgust
                end
            end
        end
    end
    
    return sentiments
end

function save_feel_file(mouvement::String, end_dict::Dict{String, Float64})
    file = "db_feel/" * mouvement * ".txt"
    dir = dirname(file)
    if !isempty(dir) && dir != "." && !isdir(dir)
        mkpath(dir)
    end
    open(file, "w") do f
        println(f, "feel;ratio")
        for (feel, ratio) in end_dict
            println(f, "$feel;$ratio")
        end
    end
end

function get_ratio_from_dict(dict::Dict{String, Float64})
    # Calcul du total des scores pour la normalisation
    total_score = sum(values(dict))

    # Normalisation des scores si le total est supérieur à zéro
    if total_score > 0
        for (key, value) in dict
            dict[key] = value / total_score
        end
    end
    
    return dict
end

function get_mouvement_probabilities_delta0(lines_livre)
    # Fait l'analyse de DB FEEL sur les lignes données, puis calcule les probabilités que ce livre apartienne à chaque mouvement à partir de cette analyse.
    
    # Faire analyse DB FEEL sur lignes données
    analyse_livre = get_ratio_from_dict(analyse_feel(lines_livre))
    
    # Prendre chaque sentiment de chaque mouvement, comparer
    mouvements_files = readdir("db_feel/")
    mouvements_ratios = Dict{String,Float64}()
    for file_name in mouvements_files
        mouvement = split(file_name, ".")[1]
        
        mouvements_ratios[mouvement] = 0.0
        global file_lines = []
        
        open("db_feel/" * file_name) do f
            file_lines = readlines(f)
        end
        
        for l in file_lines
            if startswith(l, "feel") || isempty(l)
                continue
            end
            
            all = split(l, ";")
            delta = abs(analyse_livre[all[1]] - parse(Float64, all[2]))
            #println(mouvement, " ", all[1], " ", delta)
            mouvements_ratios[mouvement] += delta
        end
    end
    
    # Ceci retourne le delta de chaque mouvement
    return mouvements_ratios
    
end

function lines_to_words_array(lines, start, stop)
    if length(lines) < start
        return []
    end
    if stop > length(lines)
        return lines[start:end]
    end
    return lines[start:stop]
end

# Debugging
if abspath(PROGRAM_FILE) == @__FILE__
    # resultats["lumieres"] = [total, justes]
    resultats = Dict()
    
    for m in readdir("book_data")
        if !contains(m, '.')
            resultats[m] = [0, 0]
            for b in readdir("book_data/$m/clean_p2")
                #println(m, " " ,b)
                open("book_data/$m/clean_p2/$b") do f
                    file_lines = readlines(f)
                    
                    if isempty(file_lines)
                        println("   -> skipped (empty file)")
                        return
                    end
                    
                    # par blocs
                    current_line = 1
                    line_size = 100
                    blocs = Dict{String,Float64}()
                    
                    while current_line <= length(file_lines)
                        res = get_mouvement_probabilities_delta0(lines_to_words_array(file_lines, current_line, current_line + line_size))
                        current_line += line_size
                        minimum = findmin(res)
                        try
                            blocs[minimum[2]] += 1
                        catch
                            blocs[minimum[2]] = 1
                        end
                    end
                    
                    if !isempty(blocs)
                        resultats[m][1] += 1
                        
                        if findmax(blocs)[2] == m
                            resultats[m][2] += 1
                        else
                            println("FAUX $m ", blocs)
                        end
                    end
                end
            end
        end
    end
    
    println(resultats)
end