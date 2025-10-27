def nettoyer_part1(filename):
    def supprimer_tout():
        # si on passe sur une ligne qui contient "Exporté de Wikisource", faut tout supp jusqu'à cette ligne-là

        pass
    
    with open(filename) as f:
        lines = f.readlines()

        # Pt 1: Supprimer tout jusqu'à "Exporté de wikisource"
        array = [l.__contains__('Exporté de wikisource') for l in lines][::-1]
        if len(set(array)) != 1:
            # Contient le texte qu'on cherche
            idx = array.rindex()
            lines = lines[idx+1:len(lines)]
        
        # Pt 2: Supprimer tout jusqu'à "MediaWiki"
        array = [l.__contains__('MediaWiki') for l in lines][::-1]
        if len(set(array)) != 1:
            # Contient le texte qu'on cherche
            idx = array.rindex()
            lines = lines[idx+1:len(lines)]
        
        # Pt 3: Supprimer les lignes jusqu'à la ligne 100 qui contient des chiffres romains (chapitres)
        

# utilisé après sauvegarde pour analyse fichier longs, nettoyage plus en détail.
def nettoyer_part2(filename):
    pass

mouvements = ["lumieres", "naturalisme", "romantisme"]