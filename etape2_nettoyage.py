def nettoyer_part1(filename):    
    with open(filename) as f:
        lines = f.readlines()

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
        # TODO

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

        # Save to file
        # TODO

# utilisé après sauvegarde pour analyse fichier longs, nettoyage plus en détail.
def nettoyer_part2(filename):
    pass

mouvements = ["lumieres", "naturalisme", "romantisme"]
#nettoyer_part1("book_data/romantisme/Atala.txt")