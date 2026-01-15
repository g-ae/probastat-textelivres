include("db_feel.jl")
include("richesse_analyse.jl")
include("longueur_phrases.jl")
include("occurrence_mots.jl")
include("themes_analyse_book.jl")

movements = ["lumieres", "naturalisme", "romantisme"]
reference = charger_reference(movements)

function calc_mouvement_proba(file_name = "")
    if isempty(file_name) return Dict{String, Float64}() end
    
    # Lecture unique du fichier
    file_lines = readlines(file_name)
    if isempty(file_lines) return Dict{String, Float64}() end
    
    proba = Dict{String, Float64}()
    
    # DB FEEL
    db_feel = db_analysis_blocks(file_lines)
    proba = mergewith(+, proba, get_ratio_from_dict(db_feel))
    
    # Niveau de langage
    proba = mergewith(+, proba, predict_movement_richesse(file_lines))

    # Longueur phrases -> baisse trop les stats
    # retour_lp = analyser_texte_inconnu_syntaxe(replace(file_name, "clean_p2" => "clean_p1"))
    # total = 0
    # for m in retour_lp
    #     total += m[2]
    # end
    # dict = Dict()
    # for m in retour_lp
    #     dict[m[1]] = m[2]/total
    # end
    # proba = mergewith(+, proba, dict)

    # Occurrence des mots
    for m in analyser_texte_inconnu(file_name, reference)
        proba = mergewith(+, proba, Dict(m[1] => m[2]))
    end

    # Analyse des thèmes
    proba = mergewith(+, proba, get_ratio_from_dict(analyse_themes(file_name)))

    return proba
end

if abspath(PROGRAM_FILE) == @__FILE__
    using Plots, StatsPlots
    results = Dict("correct" => 0, "total" => 0)
    resultats_mouv = Dict{String, Vector{Int}}()
    
    for m in movements
        dir_path = "book_data/" * m * "/clean_p2/"
        if !isdir(dir_path) continue end
        
        files = readdir(dir_path)
        valid_files = filter(f -> contains(f, '.'), files)
        
        m_correct = 0
        m_total = 0
        
        for file in valid_files
            full_path = joinpath(dir_path, file)
            proba = calc_mouvement_proba(full_path)
            
            if isempty(proba) continue end
            
            # Trouver le mouvement avec la plus haute probabilité
            predicted = reduce((x, y) -> proba[x] > proba[y] ? x : y, keys(proba))
            
            is_correct = (predicted == m)
            
            if is_correct
                m_correct += 1
                results["correct"] += 1
            end
            
            m_total += 1
            results["total"] += 1
        end
        
        resultats_mouv[m] = [m_total, m_correct]
        acc = m_total > 0 ? round(m_correct / m_total * 100, digits=2) : 0.0
        println("Précision pour $m : $acc% ($m_correct/$m_total)")
    end
    
    global_acc = results["total"] > 0 ? round(results["correct"] / results["total"] * 100, digits=2) : 0.0
    println("\nPRÉCISION GLOBALE : $global_acc% ($(results["correct"])/$(results["total"]))")

    # Sauvegarde du plot
    movements_list = String[]
    counts = Int[]
    categories = String[]

    for m in sort(collect(keys(resultats_mouv)))
        total = resultats_mouv[m][1]
        juste = resultats_mouv[m][2]
        perc = total > 0 ? round(juste / total * 100, digits=1) : 0.0
        label = "$m\n($perc%)"

        push!(movements_list, label)
        push!(counts, total)
        push!(categories, "Total")

        push!(movements_list, label)
        push!(counts, juste)
        push!(categories, "Juste")
    end

    groupedbar(movements_list, counts, group=categories, 
        title="Résultats Classification Finale (Feel + Richesse)",
        ylabel="Nombre de livres",
        legend=:topleft
    )
    savefig("plot_mouvement_final.svg")
end
