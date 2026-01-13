using CSV
using Statistics

include("occurrence_mots.jl")

# Constants
const BLOCK_SIZE = 100
const MOVEMENTS = ["lumieres", "romantisme", "naturalisme"]

function calculate_block_ttr(lines::Vector{String})
    text = join(lines, " ")
    if isempty(strip(text))
        return 0.0
    end
    
    occ_dict = occurrence_mots(text)
    
    unique_words = length(occ_dict)
    total_words = sum(values(occ_dict))
    
    if total_words == 0
        return 0.0
    end
    
    return unique_words / total_words
end

function get_richesse_per_movement()
    println("Training Richesse (TTR per $BLOCK_SIZE lines)...")
    
    stats = Dict{String, Vector{Float64}}()
    for m in MOVEMENTS
        stats[m] = Float64[]
    end
    
    for m in MOVEMENTS
        base_path = "book_data/" * m * "/clean_p2/"
        if !isdir(base_path)
            println("Directory not found: $base_path")
            continue
        end
        
        files = readdir(base_path)
        for file in files
            if !contains(file, '.') continue end
            
            full_path = joinpath(base_path, file)
            if !isfile(full_path) continue end

            lines = readlines(full_path)
            
            current_line = 1
            while current_line <= length(lines)
                end_line = min(current_line + BLOCK_SIZE - 1, length(lines))
                block = lines[current_line:end_line]
                
                ttr = calculate_block_ttr(block)
                if ttr > 0
                    push!(stats[m], ttr)
                end
                
                current_line += BLOCK_SIZE
            end
        end
    end
    
    # Save averages
    dir = "richesse_data/"
    if !isdir(dir)
        mkpath(dir)
    end
    
    for m in MOVEMENTS
        if isempty(stats[m])
            println("No data for $m")
            continue
        end
        avg_ttr = mean(stats[m])
        med_ttr = median(stats[m])
        
        open(dir * m * ".txt", "w") do f
            println(f, "$avg_ttr;$med_ttr")
        end
        println("Stats for $m => Mean: $avg_ttr | Median: $med_ttr")
    end
end

function predict_movement_richesse(lines::Vector{String})
    # Load model (Mean, Median)
    model = Dict{String, Tuple{Float64, Float64}}()
    for m in MOVEMENTS
        path = "richesse_data/" * m * ".txt"
        if isfile(path)
            content = split(read(path, String), ";")
            if length(content) >= 2
                model[m] = (parse(Float64, content[1]), parse(Float64, content[2]))
            end
        end
    end
    
    if isempty(model)
        println("No valid data inside stats files")
        return Dict{String, Float64}()
    end
    
    # Calculate text stats
    block_ttrs = Float64[]
    current_line = 1
    
    while current_line <= length(lines)
        end_line = min(current_line + BLOCK_SIZE - 1, length(lines))
        block = lines[current_line:end_line]
        
        ttr = calculate_block_ttr(block)
        if ttr > 0
            push!(block_ttrs, ttr)
        end
        current_line += BLOCK_SIZE
    end
    
    if isempty(block_ttrs)
        return Dict{String, Float64}()
    end
    
    text_mean = mean(block_ttrs)
    text_median = median(block_ttrs)
    
    # Calculate distances
    scores = Dict{String, Float64}()
    max_dist = 0.0
    
    dists = Dict{String, Float64}()
    
    # TODO: pres
    for (m, (ref_mean, ref_median)) in model
        # On donne plus de poids à la médiane pour mieux distinguer le Naturalisme
        dist = abs(text_mean - ref_mean) + 2 * abs(text_median - ref_median)
        dists[m] = dist
    end
    
    # Convert distances to probabilities (Inverse distance weighting)
    # Plus la distance est petite, plus le score est élevé
    total_inv_dist = 0.0
    epsilon = 1e-6 # Avoid division by zero
    
    for d in values(dists)
        total_inv_dist += 1.0 / (d + epsilon)
    end
    
    for (m, d) in dists
        scores[m] = (1.0 / (d + epsilon)) / total_inv_dist
    end
    
    return scores
end

if abspath(PROGRAM_FILE) == @__FILE__
    using Plots, StatsPlots

    get_richesse_per_movement()
    
    println("\nTesting Model on ALL files")
    
    total_correct = 0
    total_files = 0
    resultats = Dict{String, Vector{Int}}()
    
    for m in MOVEMENTS
        dir_path = "book_data/" * m * "/clean_p2/"
        if !isdir(dir_path) continue end
        
        files = readdir(dir_path)
        valid_files = filter(f -> contains(f, '.'), files)
        
        movement_correct = 0
        movement_total = length(valid_files)
        
        println("\nTesting MOVEMENT: $m ($movement_total files)")
        
        for file in valid_files
            full_path = joinpath(dir_path, file)
            lines = readlines(full_path)
            
            proba = predict_movement_richesse(lines)
            
            if !isempty(proba)
                best_guess = reduce((x, y) -> proba[x] > proba[y] ? x : y, keys(proba))
                
                is_correct = (best_guess == m)
                if is_correct
                    movement_correct += 1
                    global total_correct += 1
                end
            end
            global total_files += 1
        end
        
        resultats[m] = [movement_total, movement_correct]
        
        accuracy = round(movement_correct / movement_total * 100, digits=2)
        println("Accuracy for $m: $accuracy% ($movement_correct/$movement_total)")
    end
    
    if total_files > 0
        global_accuracy = round(total_correct / total_files * 100, digits=2)
        println("GLOBAL ACCURACY: $global_accuracy% ($total_correct/$total_files)")
    end

    # Sauvegarde du plot
    movements_list = String[]
    counts = Int[]
    categories = String[]

    for m in sort(collect(keys(resultats)))
        total = resultats[m][1]
        juste = resultats[m][2]
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
        title="Résultats Analyse Richesse Lexicale",
        ylabel="Nombre de livres",
        legend=:topleft
    )
    savefig("plot_richesse.svg")
end
