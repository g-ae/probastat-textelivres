const mouvements = ["lumieres", "naturalisme", "romantisme"]

# Même fonctionnement que sur nettoyage.jl -> analyse.jl va lire tous les fichiers de chaque mouvement et créer un fichier de stats pour chaque mouvement
# À voir comment structurer fichier sauvegardé

for m in mouvements
    path_to_mouvement = pwd() * "/book_data/" * m

    # Analyse des fichiers clean partie 2
    clean_p2_path = path_to_mouvement * "/clean_p2/"
    all_files = readdir(clean_p2_path)
    book_files = filter(f -> contains(f, '.'), all_files)

    for (i, file_name) in enumerate(book_files)
        println(m * "/" * file_name * " (" * string(i) * "/" * string(length(book_files)) * ")")

        # Ouvrir fichier pour récupérer son contenu
        lines = []
        open(clean_p2_path * file_name) do f
            lines = readlines(f)
        end

        # Faire analyse ici
        println(lines)
    end
end
