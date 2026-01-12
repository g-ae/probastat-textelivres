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
    
    # Reuse occurrence_mots to get counts
    occ_dict = occurrence_mots(text)
    
    unique_words = length(occ_dict)
    total_words = sum(values(occ_dict))
    
    if total_words == 0
        return 0.0
    end
    
    return unique_words / total_words
end

function get_richesse_per_movement()
    println("Training Richesse Model (TTR per $BLOCK_SIZE lines)...")
    
    stats = Dict{String, Vector{Float64}}()
    for m in MOVEMENTS
        stats[m] = Float64[]
    end
    
    for m in MOVEMENTS
        base_path = "book_data/" * m * "/clean_p2/"
        if !isdir(base_path)
            println("Warning: Directory not found: $base_path")
            continue
        end
        
        files = readdir(base_path)
        for file in files
            if !contains(file, '.') continue end # Skip directories if any
            
            full_path = joinpath(base_path, file)
            if !isfile(full_path) continue end

            lines = readlines(full_path)
            
            current_line = 1
            while current_line <= length(lines)
                end_line = min(current_line + BLOCK_SIZE - 1, length(lines))
                block = lines[current_line:end_line]
                
                ttr = calculate_block_ttr(block)
                # Filter out outliers or very small blocks if needed, but for now keep all
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
        open(dir * m * ".txt", "w") do f
            println(f, string(avg_ttr))
        end
        println("Average TTR for $m: $avg_ttr")
    end
end

function predict_movement_richesse(lines::Vector{String})
    # Load model
    model = Dict{String, Float64}()
    for m in MOVEMENTS
        path = "richesse_data/" * m * ".txt"
        if isfile(path)
            model[m] = parse(Float64, read(path, String))
        end
    end
    
    if isempty(model)
        println("No data inside stats file")
        return Dict()
    end
    
    # Process input lines in blocks and vote
    votes = Dict{String, Float64}()
    for m in keys(model)
        votes[m] = 0.0
    end
    
    current_line = 1
    total_blocks = 0
    
    while current_line <= length(lines)
        end_line = min(current_line + BLOCK_SIZE - 1, length(lines))
        block = lines[current_line:end_line]
        
        ttr = calculate_block_ttr(block)
        
        if ttr > 0
            # Find closest movement
            min_diff = Inf
            best_m = ""
            
            for (m, ref_ttr) in model
                diff = abs(ttr - ref_ttr)
                if diff < min_diff
                    min_diff = diff
                    best_m = m
                end
            end
            
            if best_m != ""
                votes[best_m] += 1
            end
            total_blocks += 1
        end
        
        current_line += BLOCK_SIZE
    end
    
    # Normalize votes
    if total_blocks > 0
        for m in keys(votes)
            votes[m] = votes[m] / total_blocks
        end
    end
    
    return votes
end

if abspath(PROGRAM_FILE) == @__FILE__
    get_richesse_per_movement()
    
    println("\nTesting Model on ALL files")
    
    total_correct = 0
    total_files = 0
    
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
        
        accuracy = round(movement_correct / movement_total * 100, digits=2)
        println("Accuracy for $m: $accuracy% ($movement_correct/$movement_total)")
    end
    
    if total_files > 0
        global_accuracy = round(total_correct / total_files * 100, digits=2)
        println("GLOBAL ACCURACY: $global_accuracy% ($total_correct/$total_files)")
    end
end
