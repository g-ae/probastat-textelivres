# Configuration de PythonCall pour utilisation du venv python
ENV["JULIA_CONDAPKG_BACKEND"] = "Null"
#ENV["JULIA_PYTHONCALL_EXE"] = ENV["VIRTUAL_ENV"] * "/bin/python3"

venv_path = get(ENV, "VIRTUAL_ENV", "")

if !isempty(venv_path)
    if Sys.iswindows()
        pyexe = joinpath(venv_path, "Scripts", "python.exe")
    else
        pyexe = joinpath(venv_path, "bin", "python3")
    end

    if isfile(pyexe)
        ENV["JULIA_PYTHONCALL_EXE"] = pyexe
    else
        @warn "Python executable not found at $pyexe; will try system python"
        syspy = Sys.which("python")
        if syspy !== nothing
            ENV["JULIA_PYTHONCALL_EXE"] = syspy
        end
    end
end

using PythonCall, InteractiveUtils

sys = pyimport("sys")
venv_path = get(ENV, "VIRTUAL_ENV", "")

println("Python utilisé: ", sys.executable)

println("Importation de spacy")
spacy = pyimport("spacy")
println("Chargement du modèle de language")
nlp = spacy.load("fr_core_news_sm", disable=["ner", "parser"])

include("occurrence_mots.jl")

const mouvements = ["lumieres", "naturalisme", "romantisme"]

for m in mouvements
    all_files = readdir(pwd() * "/book_data/" * m)
    book_files = filter(f -> contains(f, '.'), all_files)

    # sauvegardes analyses
    part1_lines = []

    for (i, file_name) in enumerate(book_files)
        println(m * "/" * file_name * " (" * string(i) * "/" * string(length(book_files)) * ")")

        # Ouvrir fichier pour récupérer son contenu
        lines = []
        open(pwd() * "/book_data/" * m * "/" * file_name) do f
            lines = readlines(f)
        end

        if length(lines) == 0
            continue
        end

        ####### Première partie du nettoyage #########

        # Supprimer tous les double-espaces
        lines = replace.(lines, r" +" => " ")

        # Supprimer tous les NBSP (Unicode A0) et Zero Width Non-Joiner
        lines = replace.(lines, r"(\u00a0|\u200c)" => "")

        # Supprimer tout jusqu'à "Exporté de Wikisouce" et "MediaWiki"
        a_supprimer = ["Exporté de Wikisource", "MediaWiki"]

        for msg in a_supprimer
            # inversion pour être sûr de trouver que la dernière valeur possible (en cas de répétition)
            array = reverse!([occursin(msg, l) for l in lines])
            if length(Set(array)) != 1
                i = findfirst(x -> x == true, array)
                if i !== nothing
                    lines = lines[length(lines)-i+2:length(lines)]
                end
            end
        end

        # Supprimer les lignes jusqu'à la ligne 100 qui contient des chiffres romains
        roman_pattern = r"^[ivxlcdmIVXLCDM]+[\s\.]"
        limit = min(100, length(lines))
        for i in limit:-1:1
            if match(roman_pattern, lines[i]) !== nothing
                deleteat!(lines, i)
            end
        end

        # Supprimer toutes les lignes après "À propos de cette étdition électronique"
        array = [occursin("À propos de cette édition électronique", l) for l in lines]
        if length(Set(array)) != 1
            i = findfirst(x -> x == true, array)
            if i !== nothing
                lines = lines[1:i-1]
            end
        end

        # Tout le texte en minuscule
        lines = lowercase.(lines)

        # Strip et suppression des lignes vides
        lines = [strip(l) for l in lines if !isempty(strip(l))]

        # Sauvegarder état
        part1_lines = [x for x in lines]

        ########### Deuxième partie du nettoyage ##############

        # Remplacer guillemets simples
        for (i, l) in enumerate(lines)
            l = replace(l, r"\b(\S)[''’]" => s"\1e ") # on garde le premier groupe de capture (\S)
            lines[i] = replace(l, "qu'" => "que ")    # qu' → que
        end

        # Supprimer tous les guillements doubles
        for (i, l) in enumerate(lines)
            #l = replace(l, r"[\"\"\"`«»‹›„‟''ʹʺ˝]" => "")
            l = replace(l, r"[\"\"\"„‟ʺ˝]" => "")
        end

        # Suppression des pronoms, déterminants et conjonctions
        pos_a_supprimer = Set(["PRON", "DET", "CCONJ", "SCONJ", "ADP", "PUNCT"])
        elisions = Set(["l", "d", "s", "c", "j", "m", "t", "n", "qu"])

        function filtrer_texte(lines, nlp, pos_a_supprimer; batch_size=50)
            println("  Traitement de $(length(lines)) lignes...")

            docs = nlp.pipe(lines, batch_size=batch_size)

            lines_filtrees = Vector{String}(undef, length(lines))

            for (i, doc) in enumerate(docs)
                tokens_gardes = String[]
                for tkn in doc
                    pos = pyconvert(String, tkn.pos_)
                    text = pyconvert(String, tkn.text)

                    # différents types de guillemets
                    #text_normalise = replace(text, r"[''’]" => "'")

                    # Filtrer
                    # Par POS
                    # Élisions (l', d', s', etc.)
                    if !(pos in pos_a_supprimer)
                        push!(tokens_gardes, text)
                    end
                end
                lines_filtrees[i] = join(tokens_gardes, " ")

                # Progression
                if i % 500 == 0
                    println("  Progression: $i/$(length(lines))")
                end
            end

            return lines_filtrees
        end

        # Utilisation avec timing
        @time lines = filtrer_texte(lines, nlp, pos_a_supprimer, batch_size=100)

        # Occurrence des mots (test)
        #save_occurrence_mots(occurrence_mots(join(lines, " ")), "occurrences_mots/" * m * "/" * file_name)

        ####### Sauvegarde fichiers #######
        println(" Sauvegarde des fichiers nettoyés")

        outdir = "book_data/" * m

        # Créer les dossiers s'ils n'existent pas
        mkpath(outdir * "/clean_p1")
        mkpath(outdir * "/clean_p2")

        # Sauvegarder partie 1
        outfile = outdir * "/clean_p1/" * file_name
        open(outfile, "w") do f
            for l in part1_lines
                println(f, l)
            end
        end

        # Sauvegarder partie 2
        outfile = outdir * "/clean_p2/" * file_name
        open(outfile, "w") do f
            for l in lines
                println(f, l)
            end
        end
    end
end
