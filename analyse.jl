include("occurrence_mots.jl")
include("longueur_phrases.jl")

const mouvements = ["lumieres", "naturalisme", "romantisme"]

# Même fonctionnement que sur nettoyage.jl -> analyse.jl va lire tous les fichiers de chaque mouvement et créer un fichier de stats pour chaque mouvement
# À voir comment structurer fichier sauvegardé

for m in mouvements
    path_to_mouvement = pwd() * "/book_data/" * m

    # Analyse des fichiers clean partie 1
    clean_p1_path = path_to_mouvement * "/clean_p1/"
    all_files = readdir(clean_p1_path)
    book_files = filter(f -> contains(f, '.'), all_files)

    dicts_longueurs_phrases::Vector{Dict{Int, Int}} = []

    for (i, file_name) in enumerate(book_files)
        println(m * "/" * file_name * " (" * string(i) * "/" * string(length(book_files)) * ")")

        # Ouvrir fichier pour récupérer son contenu
        lines = []
        open(clean_p1_path * file_name) do f
            lines = readlines(f)
        end

        # Longueur des phrases
        push!(dicts_longueurs_phrases, longueur_phrases(join(lines, " ")))
    end

    # Longueur des phrases - total
    total_longueur = concat_longueur_dicts(dicts_longueurs_phrases)
    save_longueur_phrases(total_longueur, "longueurs_phrases/" * m * "_total.txt")


    # Analyse des fichiers clean partie 2
    clean_p2_path = path_to_mouvement * "/clean_p2/"
    all_files = readdir(clean_p2_path)
    book_files = filter(f -> contains(f, '.'), all_files)

    dicts_occurrences_mots::Vector{Dict{String, Int}} = []

    for (i, file_name) in enumerate(book_files)
        println(m * "/" * file_name * " (" * string(i) * "/" * string(length(book_files)) * ")")

        # Ouvrir fichier pour récupérer son contenu
        lines = []
        open(clean_p2_path * file_name) do f
            lines = readlines(f)
        end

        # Faire analyse ici
        println(lines)

        # Occurrence des mots
        push!(dicts_occurrences_mots, occurrence_mots(join(lines, " ")))

    end

    # Occurrence des mots - total
    total_occ = concat_occurrence_dicts(dicts_occurrences_mots)
    save_occurrence_mots(total_occ, "occurrences_mots/" * m * "_total.txt")

end
