import re, os

def nettoyer_part1(filename):    
    with open(filename, encoding='utf-8') as f:
        lines = f.readlines()

        start_lines=len(lines)

        # Supprimer tout jusqu'à "Exporté de wikisource"
        array = [l.__contains__('Exporté de Wikisource') for l in lines][::-1]
        if len(set(array)) != 1:
            # Contient le texte qu'on cherche
            idx = array.index(True)
            lines = lines[len(lines)-idx+1:len(lines)]
        
        # Supprimer tout jusqu'à "MediaWiki"
        array = [l.__contains__('MediaWiki') for l in lines][::-1]
        if len(set(array)) != 1:
            # Contient le texte qu'on cherche
            idx = array.index(True)
            lines = lines[len(lines)-idx+1:len(lines)]
        
        # Supprimer les lignes jusqu'à la ligne 100 qui contient des chiffres romains (chapitres)
        roman_pattern = re.compile(r'^[ivxlcdmIVXLCDM]+[\s\.]')
        limit = min(100, len(lines))
        for idx in range(limit-1, -1, -1):
            if roman_pattern.match(lines[idx]):
                del lines[idx]

        # Supprimer toutes les lignes après "À propos de cette édition électronique" 
        array = [l.__contains__('À propos de cette édition électronique') for l in lines]
        if len(set(array)) != 1:
            # Contient le texte qu'on cherche
            idx = array.index(True)
            lines = lines[0:idx]

        # Tout le texte en minuscule
        lines = list(map(lambda x: x.lower(), lines))

        # strip
        lines = [l.strip() for l in lines]
        # Supprimer toutes les lignes vides
        lines = [l for l in lines if l != "" and l != "\n"]

        end_lines=len(lines)

        deleted_lines = start_lines - end_lines
        

        # Save to log file
        log_deleted_lines = -1
        log_kept_lines = -1
        genre = filename.split('/')[1]
        with open(f"book_data/log_{genre}.txt", encoding='utf-8') as l:
            log_deleted_lines = int(l.readline().split('=')[1])
            log_kept_lines = int(l.readline().split('=')[1])

        with open(f"book_data/log_{genre}.txt", 'w', encoding='utf-8') as l:
            l.write(f"deleted_lines={log_deleted_lines+deleted_lines}\n")
            l.write(f"kept_lines={log_kept_lines+end_lines}")
            

        # Save to file
        # TODO

# utilisé après sauvegarde pour analyse fichier longs, nettoyage plus en détail.
def nettoyer_part2(filename):
    pass

if __name__ == "__main__":
    mouvements = ["naturalisme", "romantisme"]
    for m in mouvements:
        onlyfiles = [f for f in os.
        listdir(f"book_data/{m}") if os.path.isfile(os.path.join(f"book_data/{m}", f))]
        for text_file in onlyfiles:
            print(f"book_data/{m}/{text_file}")
            nettoyer_part1(f"book_data/{m}/{text_file}")

#nettoyer_part1("book_data/romantisme/Atala.txt")
#nettoyer_part1("book_data/romantisme/Notre-Dame_de_Paris.txt")