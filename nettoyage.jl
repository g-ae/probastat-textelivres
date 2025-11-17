# Configuration de PythonCall pour utilisation du venv python
ENV["JULIA_CONDAPKG_BACKEND"] = "Null"
ENV["JULIA_PYTHONCALL_EXE"] = ENV["VIRTUAL_ENV"] * "/bin/python3"

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
	book_files = filter(f->contains(f, '.'), all_files)

	# sauvegardes analyses
	part1_lines = []
	part2_lines = []

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

		# Supprimer tout jusqu'à "Exporté de Wikisouce" et "MediaWiki"
		a_supprimer = ["Exporté de Wikisource", "MediaWiki"]

		for msg in a_supprimer
			# inversion pour être sûr de trouver que la dernière valeur possible (en cas de répétition)
			array = reverse!([occursin(msg, l) for l in lines])
			if length(Set(array)) != 1
				i = findfirst(x -> x == true, array)
				if i !== nothing
					lines = lines[length(lines) - i + 1 : length(lines)]
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
			if !occursin("'", l)
				continue
			end
			lines[i] = replace(l, r" (\S)'" => s" \1e ") # on garde le premier groupe de capture (\S)
		end

		# Suppression des pronoms, déterminants et conjonctions
		pos_a_supprimer = Set(["PRON", "DET", "CCONJ", "SCONJ", "ADP", "PUNCT"])

		function filtrer_texte(lines, nlp, pos_a_supprimer; batch_size=50)
			println("  Traitement de $(length(lines)) lignes...")
			
			docs = nlp.pipe(lines, batch_size=batch_size)
			
			lines_filtrees = Vector{String}(undef, length(lines))
			
			for (i, doc) in enumerate(docs)
				tokens_gardes = [pyconvert(String, tkn.text) 
								for tkn in doc 
								if !(pyconvert(String, tkn.pos_) in pos_a_supprimer)]
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
	
		# TODO: 
		# - sauvegarde des fichiers pour utilisation dans analyse.jl
		# - multithreading pour que spacy soit plus rapide ?
		# - se mettre d'accord sur comment sauvegarder fichiers
		# - check pour utiliser retour de filtrage texte spacy pour obtenir l'occurrence des mots (peut être possible)
	end
end