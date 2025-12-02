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
            println(mouvement, " ", all[1], " ", delta)
            mouvements_ratios[mouvement] += delta
        end
    end
    
    total = sum(values(mouvements_ratios))
    for (key, value) in mouvements_ratios
        mouvements_ratios[key] = value / total
    end
    return mouvements_ratios
    
end

# open("book_data/naturalisme/thereseraquin_zola.txt") do f
#     println(get_mouvement_probabilities_delta0(readlines(f)))
# end