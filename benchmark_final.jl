using Plots
using StatsPlots

# Chargement des modules
include("occurrence_mots.jl")
include("longueur_phrases.jl")

# CHOIX DU MODE : :vocab, :syntaxe, ou :tout
const MODE_ANALYSE = :syntaxe

function run_benchmark()
    println("DÉMARRAGE DU BENCHMARK FINAL ($MODE_ANALYSE)")
    mouvements = ["lumieres", "naturalisme", "romantisme"]

    refs_vocab = charger_reference(mouvements)

    results = Dict("correct" => 0, "total" => 0)
    resultats_mouv = Dict{String, Vector{Int}}()

    for m in mouvements
        dir_path_1 = "book_data/" * m * "/clean_p1/"
        dir_path_2 = "book_data/" * m * "/clean_p2/"

        if !isdir(dir_path_1); continue; end

        files = filter(f -> endswith(f, ".txt"), readdir(dir_path_1))

        m_correct = 0
        m_total = 0
        println("Test du mouvement : $(uppercase(m))")

        for file in files
            full_path_1 = joinpath(dir_path_1, file)
            full_path_2 = joinpath(dir_path_2, file)

            res_vocab = nothing
            res_syntax = nothing

            # Exécution conditionnelle selon le mode
            if MODE_ANALYSE == :vocab || MODE_ANALYSE == :tout
                if isfile(full_path_2)
                    res_vocab = analyser_texte_inconnu(full_path_2, refs_vocab)
                end
            end

            if MODE_ANALYSE == :syntaxe || MODE_ANALYSE == :tout
                res_syntax = analyser_texte_inconnu_syntaxe(full_path_1)
            end

            # Vérification : si une analyse active a échoué, on passe
            if (MODE_ANALYSE != :syntaxe && res_vocab === nothing) ||
               (MODE_ANALYSE != :vocab && res_syntax === nothing)
                continue
            end

            # SYSTEME DE VOTE
            points = Dict("lumieres" => 0, "naturalisme" => 0, "romantisme" => 0)

            # Vocabulaire
            if res_vocab !== nothing
                for (i, (pred_mvt, score)) in enumerate(res_vocab)
                    points[pred_mvt] += (4 - i) # +3, +2, +1
                end
            end

            # Syntaxe
            if res_syntax !== nothing
                for (i, (pred_mvt, score)) in enumerate(res_syntax)
                    points[pred_mvt] += (4 - i) # +3, +2, +1
                end
            end

            # Le vainqueur
            vainqueur = sort(collect(points), by=x->x[2], rev=true)[1][1]

            # Vérification
            if vainqueur == m
                m_correct += 1
                results["correct"] += 1
            end
            m_total += 1
            results["total"] += 1
        end

        resultats_mouv[m] = [m_total, m_correct]
        acc = m_total > 0 ? round(m_correct / m_total * 100, digits=2) : 0.0
        println("Précision : $acc% ($m_correct/$m_total)")
    end

    global_acc = results["total"] > 0 ? round(results["correct"] / results["total"] * 100, digits=2) : 0.0
    println("PRÉCISION GLOBALE : $global_acc%")

    # Génération du graphique
    generer_graphique_resultats(resultats_mouv)
end

function generer_graphique_resultats(resultats_mouv)
    movements_list = String[]
    counts = Int[]
    categories = String[]

    for m in sort(collect(keys(resultats_mouv)))
        total = resultats_mouv[m][1]
        juste = resultats_mouv[m][2]
        perc = total > 0 ? round(juste / total * 100, digits=1) : 0.0
        label = "$(uppercase(m))\n($perc%)"

        push!(movements_list, label); push!(counts, total); push!(categories, "Total")
        push!(movements_list, label); push!(counts, juste); push!(categories, "Correct")
    end

    groupedbar(movements_list, counts, group=categories,
        title="Performance Classification ($MODE_ANALYSE)",
        ylabel="Nombre de livres", bar_position = :overlay,
        color = [:green :gray], alpha = [1.0 0.5], legend=:topleft
    )
    savefig("resultat_final_benchmark_$MODE_ANALYSE.png")
end

run_benchmark()