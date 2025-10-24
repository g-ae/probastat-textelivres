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
            headers = {
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:143.0) Gecko/20100101 Firefox/143.0'
            }
            r = requests.get("https://ws-export.wmcloud.org/?format=epub&lang=fr&page=" + row["URL"].split('/wiki/')[1], headers=headers)

            if r.status_code == 200:
                content_disposition = r.headers.get("content-disposition", "")
                filename = "fichier.epub"
                if "filename=" in content_disposition:
                    filename = content_disposition.split("filename=")[-1].strip('"')

                with open(filename, "wb") as f:
                    for chunk in r.iter_content(chunk_size=8192):
                        f.write(chunk)
            else:
                print(row, "Erreur", r)
            
            exit(1)
            