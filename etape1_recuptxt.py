import sys, requests, os, csv

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Missing args")
        print("Usage : python3 recup_txt.py data.csv")
        exit(1)
    
    if not os.path.isdir("book_data"):
        os.mkdir("book_data")

    book_dir = ["lumieres", "romantisme", "naturalisme"]

    for b in book_dir:
        if not os.path.isdir("book_data/" + b):
            os.mkdir("book_data/" + b)

    with open(sys.argv[1]) as f:
        reader = csv.DictReader(f, delimiter=';')

        for row in reader:
            print(row)
            file_url = f"book_data/{row["MOUVEMENT"]}/{row["NOM_FICHIER"]}"
            print(row["URL"])
            data = requests.get(row["URL"]).text

            if not os.path.exists(file_url):
                open(file_url, "x") # create file
            n = open(file_url, "w") # update file
            n.write(data)