using InteractiveUtils
include("occurrence_mots.jl")

const mouvements = ["lumieres", "naturalisme", "romantisme"]

for m in mouvements
	all_files = readdir(pwd() * "/book_data/" * m)
	book_files = filter(f->contains(f, '.'), all_files)
	for file_name in book_files
		println(m * "/" * file_name)

		# Ouvrir fichier pour récupérer son contenu
		lines = []
		open(pwd() * "/book_data/" * m * "/" * file_name) do f
			lines = readlines(f)
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
				lines = lines[1:i]
			end
		end

		# Tout le texte en minuscule
		lines = lowercase.(lines)

		# Strip et suppression des lignes vides
		lines = [strip(l) for l in lines if !isempty(strip(l))]
		
		########### Deuxième partie du nettoyage ##############
		
		
		########### Occurrence des mots (test) ###########
		save_occurrence_mots(occurrence_mots(join(lines, " ")), "occurrences_mots/" * m * "/" * file_name)
	end
end