# BLACKLIST (Patronymes, lieux uniques et bruit) - Liste générée par IA
function get_blacklist()
    return Set([
        # === 1. BRUIT ANGLAIS TRONQUÉ (STAMMED) ===
        "thi", "provid", "distribut", "includ", "stat", "damag", "us", "can",
        "electr", "foundat", "copi", "copy", "project", "gutenberg", "archiv",
        "work", "licens", "term", "agreem", "copyright", "public", "domain",
        "law", "unit", "state", "complianc", "requir", "restrict", "violat",
        "access", "liabil", "warranti", "disclaim", "limit", "indemnifi",
        "refund", "replac", "defect", "neglig", "breach", "contract", "tort",
        "merchant", "fit", "purpos", "incid", "consequ", "punit", "applic",
        "proprietari", "intellectu", "properti", "fil", "comput", "system",
        "viru", "format", "readabl", "binari", "compress", "download", "onlin",
        "network", "server", "post", "locat", "associ", "provid", "forth",
        "full", "legal", "http", "www", "org", "net", "com", "html", "txt",
        "ascii", "zip", "email", "volunt", "newslett", "donat", "chariti",
        "payment", "credit", "card", "check",
        "the", "and", "that", "with", "from", "have", "which", "you", "one",
        "all", "not", "are", "was", "but", "for", "may", "can", "very", "what",

        # === 1. VOCABULAIRE TECHNIQUE & JURIDIQUE (Licences Anglaises) ===
        # Mots courants de la licence Project Gutenberg
        "project", "gutenberg", "literary", "archive", "foundation",
        "electronic", "work", "works", "license", "terms", "agreement",
        "copyright", "domain", "public", "united", "states", "law", "laws",
        "access", "distribute", "distributed", "copy", "copies", "copying",
        "damages", "liability", "warranty", "disclaimer", "limitation", "indemnify",
        "refund", "replacement", "donation", "charity", "donations",
        "file", "files", "data", "computer", "system", "virus", "defect",
        "format", "readable", "processor", "online", "network", "posted",
        "this", "that", "with", "from", "have", "which", "form", "days",
        "about", "associated", "compliance", "country", "forth", "located",
        "http", "www", "org", "net", "com", "html", "txt", "ascii", "holder", "check",
        "proofreading", "team", "digitized", "produced", "by", "of", "and", "the", "in", "to", "or", "is", "for", # Petits mots anglais fréquents

        # === 1. DERNIERS AJOUTS  ===
        "foundation", "access", "damages", "located", # Anglais
        "cazotte",
        "compliance", "country", "distribute", "copy", "forth",
        "julielettre", "ferval", "zurich", "omphale", "gangarides",

        # === 2. BRUIT INFORMATIQUE (Mots anglais des licences Gutenberg/Archive) ===
        "this", "that", "with", "from", "have", "which", "form", "days",
        "agreement", "requirements", "posted", "associated", "about", "work",
        "works", "terms", "license", "online", "distributed", "proofreading",
        "team", "file", "http", "www", "gutenberg", "archive", "digitized",
        "project", "ebook", "ebooks", "title", "author", "language", "release",
        "fees", "may", "used", "anyone", "anywhere", "subject", "special", "permissions", "see", "details", "distribution",
        "modification", "under", "copyright", "laws", "public", "domain", "reading",
        "rights", "reserved", "donate", "contributions", "support", "online", "copyright",
        "including", "using", "other",

        # === 3. PERSONNAGES & LIEUX (Détails littéraires) ===
        # === LUMIÈRES ===
        # Voltaire (Noms uniques seulement)
        "pangloss", "cunégonde", "cacambo", "zadig", "astarté", "moabdar",
        "micromégas", "kerkabon", "formosante", "amazan", "babylone", "sirius",
        # Montesquieu
        "usbek", "rica", "roxane", "ispahan", "nadié", "zachi",
        # Prévost & Marivaux
        "lescaut", "grieux", "tiberge", "cleveland", "axminster",
        "valville", "climal", "dutour", "habert", "fécour",
        # Rousseau
        "wolmar", "saint-preux", "étampes", "clarens", "héloïse",
        # Diderot
        "simonin", "arpajon", "mirzoza", "mangogul", "zaïde", "iwan",
        # Laclos & Sade
        "merteuil", "valmont", "tourvel", "volanges", "rosemonde", "danceny",
        "blamont", "noirceuil", "saint-fond", "rodin", "sade",
        # Lesage & Autres
        "santillane", "sangrado", "asmodée", "cléofas", "zambullo",
        "alvare", "biondetta", "soberano", "télémaque", "calypso", "idoménée",
        "amanzéi", "phénime", "zulica", "meilcour", "lursay", "zilia", "aza", "déterville",
        "joannetti", "corinne", "oswald", "nelvil", "lucile", "delphine", "albemar", "léonce",
        "ellénore", "oberman",

        # === ROMANTISME ===
        # Chateaubriand
        "atala", "chactas", "celuta", "aubry",
        # Hugo (Noms distinctifs)
        "esmeralda", "quasimodo", "frollo", "gringoire", "phoebus",
        "valjean", "javert", "cosette", "marius", "gavroche", "thenardier", "fantine", "myriel",
        "ordener", "schumacker", "bug-jargal", "habibrah",
        "gilliatt", "déruchette", "lethierry", "gwynplaine", "dea", "ursus", "josiana",
        "lantenac", "gauvain", "cimourdain",
        # Dumas
        "artagnan", "athos", "porthos", "aramis", "tréville", "planchet",
        "dantes", "edmond", "monte-cristo", "faria", "mercedes", "mondego", "danglars", "villefort",
        "mordaunt", "mazarin", "raoul", "bragelonne", "fouquet", "vallière",
        "coconnas", "bussy", "monsoreau", "chicot", "balsamo",
        # Sand
        "indiana", "ralph", "raymon", "delmare", "lélia", "sténio", "trenmor",
        "consuelo", "porpora", "rudolstadt", "fadette", "landry", "sylvinet", "fanchon",
        "mauprat", "edmée",
        # Vigny, Musset, Mérimée...
        "cinq-mars", "stello", "collingwood", "sylvie", "aurélia",
        "colomba", "orso", "rebbia", "carmen", "escamillo", "maupin", "graziella", "amaury", "couaën",

        # === NATURALISME ===
        # Zola (Rougon-Macquart)
        "gervaise", "coupeau", "nana", "goujet", "lorilleux", "boche",
        "lantier", "maheu", "maheude", "chaval", "hennebeau", "souvarine", "negrel", "voreux",
        "muffat", "fontan", "satin", "roubaud", "severine", "pecqueux", "misard",
        "baudu", "mouret", "bourdoncle", "hutin", "josserand", "campardon",
        "saccard", "renée", "albine", "désirée", "florent", "quenu", "gradelle",
        "raquin", "rougon", "macquart", "silvère", "miette", "adélaïde",
        "clorinde", "sandoz", "fouan", "buteau", "gundermann",
        # Maupassant
        "lamare", "rosalie", "duroy", "forestier", "walter", "andermatt", "guilleroy", "mariolle",
        # Huysmans & Autres
        "desesseintes", "durtal", "hermies", "chantelouve", "vatard", "cyprien", "folantin",
        "germinie", "lacerteux", "jupillon", "gervaisais", "vingtras", "mintié"
    ])
end