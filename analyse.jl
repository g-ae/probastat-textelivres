include("occurrence_mots.jl")
include("longueur_phrases.jl")
include("db_feel.jl")
include("richesse_analyse.jl")

const mouvements = ["lumieres", "naturalisme", "romantisme"]

# Même fonctionnement que sur nettoyage.jl -> analyse.jl va lire tous les fichiers de chaque mouvement et créer un fichier de stats pour chaque mouvement
# À voir comment structurer fichier sauvegardé

for m in mouvements
    println("Analyse mouvment " * m)
    path_to_mouvement = pwd() * "/book_data/" * m

    # Analyse des fichiers clean partie 1
    clean_p1_path = path_to_mouvement * "/clean_p1/"
    all_files = readdir(clean_p1_path)
    book_files = filter(f -> contains(f, '.'), all_files)

    total_longueurs_mvt = Int[]

    for (i, file_name) in enumerate(book_files)
        println(m * "/" * file_name * " (" * string(i) * "/" * string(length(book_files)) * ") -> clean_p1")

        # Ouvrir fichier pour récupérer son contenu
        lines = []
        open(clean_p1_path * file_name) do f
            lines = readlines(f)
        end

        # Longueur des phrases
        longueurs = longueur_phrases(join(lines, " "))
        append!(total_longueurs_mvt, longueurs)
    end

    # Longueur des phrases - total (sauvegarde le vecteur via la fonction existante)
    save_longueur_phrases(total_longueurs_mvt, "longueurs_phrases/" * m * "_total.txt")


    # Analyse des fichiers clean partie 2
    clean_p2_path = path_to_mouvement * "/clean_p2/"
    all_files = readdir(clean_p2_path)
    book_files = filter(f -> contains(f, '.'), all_files)

    dicts_occurrences_mots::Vector{Dict{String, Int}} = []
    
    dict_feel = Dict(
        "joy" => 0.0,
        "fear" => 0.0,
        "sadness" => 0.0,
        "anger" => 0.0,
        "surprise" => 0.0,
        "disgust" => 0.0
    )

    for (i, file_name) in enumerate(book_files)
        println(m * "/" * file_name * " (" * string(i) * "/" * string(length(book_files)) * ") -> clean_p2")

        # Ouvrir fichier pour récupérer son contenu
        lines = []
        open(clean_p2_path * file_name) do f
            lines = readlines(f)
        end

        # Occurrence des mots
        push!(dicts_occurrences_mots, occurrence_mots(join(lines, " ")))

        # Base de données FEEL
        for (sentiment, value) in analyse_feel(lines)
            dict_feel[sentiment] += value
        end
    end

    # Occurrence des mots - total
    total_occ = concat_occurrence_dicts(dicts_occurrences_mots)
    save_occurrence_mots(total_occ, "occurrences_mots/" * m * "_total.csv")

    # Sauvegarde db feels par mouvement
    get_ratio_from_dict(dict_feel)
    save_feel_file(m, dict_feel)
end

# Création fichiers "richesse lexicale" -> gère mouvements tout seul
get_richesse_per_movement()
