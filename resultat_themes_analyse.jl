using CSV
using DataFrames
using Glob

function summary_for_movement(movement::String)

    println("\nCréation du fichier de résultats pour : $movement")

    result_dir = joinpath("themes_data", movement)
    isdir(result_dir) || mkpath(result_dir)

    files = Glob.glob("data_*.csv", result_dir)

    livres = String[]
    courants = String[]

    count_rom = 0
    count_nat = 0
    count_lum = 0

    for f in files
        df = CSV.read(f, DataFrame)

        last3 = df[end-2:end, :]

        total_rom = last3[last3.theme .== "TOTAL_romantisme", :count][1]
        total_nat = last3[last3.theme .== "TOTAL_naturalisme", :count][1]
        total_lum = last3[last3.theme .== "TOTAL_lumieres", :count][1]

        totals = Dict(
            "romantisme" => total_rom,
            "naturalisme" => total_nat,
            "lumieres" => total_lum
        )

        courant = argmax(totals)

        if courant == "romantisme"
            count_rom += 1
        elseif courant == "naturalisme"
            count_nat += 1
        else
            count_lum += 1
        end

        livre_name = replace(basename(f), ("data_" => ""), (".csv" => ""))

        push!(livres, livre_name)
        push!(courants, courant)
    end

    result_df = DataFrame(
        livre = livres,
        courant_detecte = courants
    )

    push!(result_df, ("TOTAL_romantisme", string(count_rom)))
    push!(result_df, ("TOTAL_naturalisme", string(count_nat)))
    push!(result_df, ("TOTAL_lumieres", string(count_lum)))

    out_path = joinpath(result_dir, "resultat_$(movement).csv")
    CSV.write(out_path, result_df)

    println("→ Fichier généré : $out_path")
end

#appel ---------------------------------------------

summary_for_movement("romantisme")
#summary_for_movement("naturalisme")
#summary_for_movement("lumieres")
