using CSV, DataFrames

include("occurrence_mots.jl")

path = pwd() * "/FEEL.csv"
csv_data = DataFrame(CSV.File(path, delim=';'))

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
                # On cherche le mot dans la colonne 'word' du DataFrame
                rows = filter(row -> row.word == mot, csv_data)

                if !isempty(rows)
                    # Si le mot est trouvé, on ajoute ses scores de sentiment
                    # On prend la première ligne trouvée au cas où il y aurait des doublons
                    word_scores = rows[1, :]
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
    # Calcul du total des scores pour la normalisation
    total_score = sum(values(sentiments))

    # Normalisation des scores si le total est supérieur à zéro
    if total_score > 0
        for (key, value) in sentiments
            sentiments[key] = value / total_score
        end
    end

    return sentiments
end
