defmodule Ret.Chemistry do
  @moduledoc """
  Chemistry element definitions and validation for chemistry education rooms.

  Provides compile-time element data (118 elements) and validation functions
  used by the room creation API to store chemistry metadata in `user_data`.
  """

  @type element_group :: :nonmetal | :nobleGas | :alkali | :alkalineEarth | :metalloid | :halogen | :transition | :metal | :lanthanide | :actinide

  @type element :: %{
    symbol: String.t(),
    name: String.t(),
    atomic_number: non_neg_integer(),
    mass: float(),
    group: element_group(),
    period: pos_integer(),
    block: String.t(),
    group_number: pos_integer(),
    color: non_neg_integer(),
    description: String.t(),
    theme: String.t(),
    experiments: [String.t()]
  }

  @valid_groups [:nonmetal, :nobleGas, :alkali, :alkalineEarth, :metalloid, :halogen, :transition, :metal, :lanthanide, :actinide]

  @elements [
    %{symbol: "H",  name: "Wasserstoff",      atomic_number: 1,  mass: 1.008,  group: :nonmetal,      period: 1, block: "s", group_number: 1,  color: 0xFFFFFF, description: "Das häufigste Element im Universum. Treibstoff der Sterne, Baustein des Wassers.", theme: "cosmic", experiments: ["knallgas", "fusion", "fuelcell"]},
    %{symbol: "He", name: "Helium",           atomic_number: 2,  mass: 4.003,  group: :nobleGas,      period: 1, block: "s", group_number: 18, color: 0xFFFFFF, description: "Das zweithäufigste Element im Universum. Leichter als Luft, macht Ballons schweben.", theme: "cosmic", experiments: ["balloon", "superfluid", "laser"]},
    %{symbol: "Li", name: "Lithium",          atomic_number: 3,  mass: 6.94,   group: :alkali,        period: 2, block: "s", group_number: 1,  color: 0xFF6B6B, description: "Leichtestes Metall. Wichtig für Akkus und Batterien. Reagiert heftig mit Wasser.", theme: "battery", experiments: ["water", "flame", "battery"]},
    %{symbol: "Be", name: "Beryllium",        atomic_number: 4,  mass: 9.012,  group: :alkalineEarth,  period: 2, block: "s", group_number: 2,  color: 0xE8D5B7, description: "Hochgiftiges Metall mit niedriger Dichte. Verwendet in der Weltraumtechnik.", theme: "gem", experiments: ["crystal", "toxicity"]},
    %{symbol: "B",  name: "Bor",              atomic_number: 5,  mass: 10.81,  group: :metalloid,     period: 2, block: "p", group_number: 13, color: 0xC0C0C0, description: "Hartes Material für Glasfasern. Kommt in Wüstensalzen vor.", theme: "desert", experiments: ["borax", "fiberglass"]},
    %{symbol: "C",  name: "Kohlenstoff",      atomic_number: 6,  mass: 12.011, group: :nonmetal,      period: 2, block: "p", group_number: 14, color: 0xFFC107, description: "Das Element des Lebens. Grundbaustein aller organischen Verbindungen.", theme: "life", experiments: ["diamond", "graphite", "dna"]},
    %{symbol: "N",  name: "Stickstoff",       atomic_number: 7,  mass: 14.007, group: :nonmetal,      period: 2, block: "p", group_number: 15, color: 0xFFC107, description: "Macht 78% der Atmosphäre aus. Essentiell für Proteine und DNA.", theme: "atmosphere", experiments: ["liquid", "haberbosch", "fertilizer"]},
    %{symbol: "O",  name: "Sauerstoff",       atomic_number: 8,  mass: 15.999, group: :nonmetal,      period: 2, block: "p", group_number: 16, color: 0xFFC107, description: "Zweithäufigstes Element im Universum. Notwendig für Atmung und Verbrennung.", theme: "breath", experiments: ["combustion", "ozone", "photosynthesis"]},
    %{symbol: "F",  name: "Fluor",            atomic_number: 9,  mass: 18.998, group: :halogen,       period: 2, block: "p", group_number: 17, color: 0x00FF00, description: "Reaktivstes aller Elemente. Wird in Teflon und Zahncreme verwendet.", theme: "protection", experiments: ["reaction", "teflon"]},
    %{symbol: "Ne", name: "Neon",             atomic_number: 10, mass: 20.180, group: :nobleGas,      period: 2, block: "p", group_number: 18, color: 0xFF6B6B, description: "Leuchtet bei elektrischer Entladung orange-rot. Symbol der Stadtbeleuchtung.", theme: "lights", experiments: ["neon", "laser"]},
    %{symbol: "Na", name: "Natrium",          atomic_number: 11, mass: 22.990, group: :alkali,        period: 3, block: "s", group_number: 1,  color: 0xFF6B6B, description: "Silberglänzendes Metall, butterweich. Basis für Speisesalz (NaCl).", theme: "kitchen", experiments: ["water", "flame", "saltcrystal"]},
    %{symbol: "Mg", name: "Magnesium",        atomic_number: 12, mass: 24.305, group: :alkalineEarth,  period: 3, block: "s", group_number: 2,  color: 0xE8D5B7, description: "Blendend weißes Licht beim Verbrennen. Kommt in Chlorophyll vor.", theme: "light", experiments: ["flash", "chlorophyll", "alloy"]},
    %{symbol: "Al", name: "Aluminium",        atomic_number: 13, mass: 26.982, group: :metal,         period: 3, block: "p", group_number: 13, color: 0xC0C0C0, description: "Das häufigste Metall der Erdkruste. Leicht und korrosionsbeständig.", theme: "industry", experiments: ["hallheroult", "thermit", "foil"]},
    %{symbol: "Si", name: "Silizium",         atomic_number: 14, mass: 28.086, group: :metalloid,     period: 3, block: "p", group_number: 14, color: 0xC0C0C0, description: "Zweithäufigstes Element der Erdkruste. Basis aller modernen Elektronik.", theme: "silicon", experiments: ["transistor", "solar", "sand"]},
    %{symbol: "P",  name: "Phosphor",         atomic_number: 15, mass: 30.974, group: :nonmetal,      period: 3, block: "p", group_number: 15, color: 0xFFC107, description: "Glüht weiß im Dunkeln. Wichtiger Bestandteil von DNA und ATP.", theme: "fire", experiments: ["white", "red", "match"]},
    %{symbol: "S",  name: "Schwefel",         atomic_number: 16, mass: 32.065, group: :nonmetal,      period: 3, block: "p", group_number: 16, color: 0xFFC107, description: "Gelbes Element mit charakteristischem Geruch. Kommt in Vulkanen vor.", theme: "volcano", experiments: ["burning", "gunpowder", "bromo"]},
    %{symbol: "Cl", name: "Chlor",            atomic_number: 17, mass: 35.453, group: :halogen,       period: 3, block: "p", group_number: 17, color: 0x00FF00, description: "Grün-gelbes Giftgas. Wird zur Wasserdesinfektion verwendet.", theme: "swimming", experiments: ["disinfection", "salt", "gas"]},
    %{symbol: "Ar", name: "Argon",            atomic_number: 18, mass: 39.948, group: :nobleGas,      period: 3, block: "p", group_number: 18, color: 0x00BFFF, description: "Häufigstes Edelgas (1% Atmosphäre). Wird für WIG-Schweißen verwendet.", theme: "welding", experiments: ["plasma", "inert"]},
    %{symbol: "K",  name: "Kalium",           atomic_number: 19, mass: 39.098, group: :alkali,        period: 4, block: "s", group_number: 1,  color: 0xFF6B6B, description: "Reaktives Metall, in Natur oft als Ion. Wesentlich für biologische Prozesse.", theme: "biological", experiments: ["water", "flame", "banane"]},
    %{symbol: "Ca", name: "Calcium",          atomic_number: 20, mass: 40.078, group: :alkalineEarth,  period: 4, block: "s", group_number: 2,  color: 0xE8D5B7, description: "Fünft-häufigstes Element der Erdkruste. Wichtig für Knochen und Zähne.", theme: "skeleton", experiments: ["burning", "bones", "limestone"]},
    %{symbol: "Sc", name: "Scandium",         atomic_number: 21, mass: 44.956, group: :transition,     period: 4, block: "d", group_number: 3,  color: 0xC0C0C0, description: "Seltenes Übergangsmetall. Wird in Sportgeräten und Hochleistungslegierungen verwendet.", theme: "aerospace", experiments: ["alloy", "magnetic", "sport"]},
    %{symbol: "Ti", name: "Titan",            atomic_number: 22, mass: 47.867, group: :transition,     period: 4, block: "d", group_number: 4,  color: 0xC0C0C0, description: "Korrosionsbeständiges Metall mit hohem Schmelzpunkt. Für Luft- und Raumfahrtindustrie.", theme: "aerospace", experiments: ["biokompatibilität", "legierung", "oxid"]},
    %{symbol: "V",  name: "Vanadium",         atomic_number: 23, mass: 50.942, group: :transition,     period: 4, block: "d", group_number: 5,  color: 0xC0C0C0, description: "Hartes, grau-weißes Metall. Für Werkzeugstahl und Titanlegierungen.", theme: "industry", experiments: ["stahl", "legierung", "katalysator"]},
    %{symbol: "Cr", name: "Chrom",            atomic_number: 24, mass: 51.996, group: :transition,     period: 4, block: "d", group_number: 6,  color: 0xC0C0C0, description: "Glänzendes, korrosionsbeständiges Metall. Basis von Edelstahl und Verchromung.", theme: "industry", experiments: ["edelstahl", "verchromung", "pigment"]},
    %{symbol: "Mn", name: "Mangan",           atomic_number: 25, mass: 54.938, group: :transition,     period: 4, block: "d", group_number: 7,  color: 0xC0C0C0, description: "Wichtig für Stahlherstellung. Bioelement für Photosynthese.", theme: "industry", experiments: ["stahl", "photosynthese", "batterie"]},
    %{symbol: "Fe", name: "Eisen",            atomic_number: 26, mass: 55.845, group: :transition,     period: 4, block: "d", group_number: 8,  color: 0xC0C0C0, description: "Wichtigstes Metall der Menschheit. Grundbaustein von Stahl und Hämoglobin.", theme: "forge", experiments: ["magnet", "rust", "steel"]},
    %{symbol: "Co", name: "Kobalt",           atomic_number: 27, mass: 58.933, group: :transition,     period: 4, block: "d", group_number: 9,  color: 0xC0C0C0, description: "Blau-graues, ferromagnetisches Metall. Für Supraleger, Magnete und Batterien.", theme: "technology", experiments: ["magnet", "batterie", "legierung"]},
    %{symbol: "Ni", name: "Nickel",           atomic_number: 28, mass: 58.693, group: :transition,     period: 4, block: "d", group_number: 10, color: 0xC0C0C0, description: "Silbrig-weißes, korrosionsbeständiges Metall. Münzmetall und für Legierungen.", theme: "technology", experiments: ["münzen", "legierung", "katalysator"]},
    %{symbol: "Cu", name: "Kupfer",           atomic_number: 29, mass: 63.546, group: :transition,     period: 4, block: "d", group_number: 11, color: 0xC0C0C0, description: "Erstes Metall der Menschheit. Exzellenter elektrischer Leiter.", theme: "electric", experiments: ["conductivity", "patina", "bronze"]},
    %{symbol: "Zn", name: "Zink",             atomic_number: 30, mass: 65.38,  group: :transition,     period: 4, block: "d", group_number: 12, color: 0xC0C0C0, description: "Reaktionsfreies Metall. Für galvanische Zellen, Verzinkung und Legierungen.", theme: "technology", experiments: ["galvanik", "verzinkung", "batterie"]},
    %{symbol: "Ga", name: "Gallium",          atomic_number: 31, mass: 69.723, group: :metal,         period: 4, block: "p", group_number: 13, color: 0xC0C0C0, description: "Schmilzt in der Hand bei Raumtemperatur. Für Halbleiter.", theme: "semiconductor", experiments: ["schmelzen", "halbleiter", "thermometer"]},
    %{symbol: "Ge", name: "Germanium",        atomic_number: 32, mass: 72.630, group: :metalloid,     period: 4, block: "p", group_number: 14, color: 0xC0C0C0, description: "Halbleiter für Transistoren und Optoelektronik.", theme: "semiconductor", experiments: ["halbleiter", "transistor", "faser"]},
    %{symbol: "As", name: "Arsen",            atomic_number: 33, mass: 74.922, group: :metalloid,     period: 4, block: "p", group_number: 15, color: 0xC0C0C0, description: "Sehr giftiges Halbmetall. Historisch in Tapeten und Farben verwendet.", theme: "toxic", experiments: ["gift", "historisch", "semiconductor"]},
    %{symbol: "Se", name: "Selen",            atomic_number: 34, mass: 78.96,  group: :nonmetal,      period: 4, block: "p", group_number: 16, color: 0xFFC107, description: "Wichtiges Spurenelement. Halbleiter und für Glühbirnen.", theme: "semiconductor", experiments: ["glühbirne", "photovoltaik", "toxisch"]},
    %{symbol: "Br", name: "Brom",             atomic_number: 35, mass: 79.904, group: :halogen,       period: 4, block: "p", group_number: 17, color: 0x00FF00, description: "Einziges flüssiges Nichtmetall bei Raumtemperatur.", theme: "liquid", experiments: ["flüssig", "flammmittel", "giftig"]},
    %{symbol: "Kr", name: "Krypton",          atomic_number: 36, mass: 83.798, group: :nobleGas,      period: 4, block: "p", group_number: 18, color: 0x00BFFF, description: "Edelgas mit hoher Dichte. Für Blitzlichtlampen und Laser.", theme: "lighting", experiments: ["laser", "neon", "isoliert"]},
    %{symbol: "Rb", name: "Rubidium",         atomic_number: 37, mass: 85.468, group: :alkali,        period: 5, block: "s", group_number: 1,  color: 0xFF6B6B, description: "Weiches, hochreaktives Metall. Für Atomuhren und Feuerwerk.", theme: "pyrotechnics", experiments: ["atomuhr", "feuerwerk", "reaktion"]},
    %{symbol: "Sr", name: "Strontium",        atomic_number: 38, mass: 87.62,  group: :alkalineEarth,  period: 5, block: "s", group_number: 2,  color: 0xE8D5B7, description: "Für rote Feuerwerke und Magnete. Radioaktiv (Strontium-90).", theme: "pyrotechnics", experiments: ["feuerwerk", "magnet", "radioaktiv"]},
    %{symbol: "Y",  name: "Yttrium",          atomic_number: 39, mass: 88.906, group: :transition,     period: 5, block: "d", group_number: 3,  color: 0xC0C0C0, description: "Seltenes Erdelement. Für LEDs, Supraleiter und Laser.", theme: "technology", experiments: ["led", "laser", "supraleiter"]},
    %{symbol: "Zr", name: "Zirkonium",        atomic_number: 40, mass: 91.224, group: :transition,     period: 5, block: "d", group_number: 4,  color: 0xC0C0C0, description: "Korrosionsbeständiges Metall. Für Kernelemente und medizinische Implantate.", theme: "nuclear", experiments: ["kernelement", "implantat", "keramik"]},
    %{symbol: "Nb", name: "Niob",             atomic_number: 41, mass: 92.906, group: :transition,     period: 5, block: "d", group_number: 5,  color: 0xC0C0C0, description: "Supraleiter bei niedrigen Temperaturen.", theme: "technology", experiments: ["supraleiter", "magnet", "hochspannung"]},
    %{symbol: "Mo", name: "Molybdän",         atomic_number: 42, mass: 95.95,  group: :transition,     period: 5, block: "d", group_number: 6,  color: 0xC0C0C0, description: "Extrem hartes Metall. Für Hochtemperaturanwendungen.", theme: "industry", experiments: ["hochtemperatur", "schmiermittel", "stahl"]},
    %{symbol: "Tc", name: "Technetium",       atomic_number: 43, mass: 98.0,   group: :transition,     period: 5, block: "d", group_number: 7,  color: 0xC0C0C0, description: "Erstes künstliches Element. Radioaktiv. In der medizinischen Bildgebung.", theme: "nuclear", experiments: ["künstlich", "medizin", "radioaktiv"]},
    %{symbol: "Ru", name: "Ruthenium",        atomic_number: 44, mass: 101.07, group: :transition,     period: 5, block: "d", group_number: 8,  color: 0xC0C0C0, description: "Seltenes, aber wichtiges Metall. Für Elektronikkontakte und Katalysatoren.", theme: "technology", experiments: ["katalysator", "kontakte", "legierung"]},
    %{symbol: "Rh", name: "Rhodium",          atomic_number: 45, mass: 102.91, group: :transition,     period: 5, block: "d", group_number: 9,  color: 0xC0C0C0, description: "Sehr wertvolles Übergangsmetall. Für Katalysatoren und Schmuck.", theme: "technology", experiments: ["katalysator", "schmuck", "thermo"]},
    %{symbol: "Pd", name: "Palladium",        atomic_number: 46, mass: 106.42, group: :transition,     period: 5, block: "d", group_number: 10, color: 0xC0C0C0, description: "Wertvolles Platin-Metall. Für Katalysatoren, Schmuck und Wasserstofffilter.", theme: "technology", experiments: ["katalysator", "schmuck", "wasserstoff"]},
    %{symbol: "Ag", name: "Silber",           atomic_number: 47, mass: 107.87, group: :transition,     period: 5, block: "d", group_number: 11, color: 0xC0C0C0, description: "Bester elektrischer Leiter aller Metalle.", theme: "precious", experiments: ["elektrisch", "schmuck", "fotografie"]},
    %{symbol: "Cd", name: "Cadmium",          atomic_number: 48, mass: 112.41, group: :transition,     period: 5, block: "d", group_number: 12, color: 0xC0C0C0, description: "Giftiges Metall. Für NiCd-Batterien, Pigmente und galvanische Elemente.", theme: "toxic", experiments: ["batterie", "pigment", "toxisch"]},
    %{symbol: "In", name: "Indium",           atomic_number: 49, mass: 114.82, group: :metal,         period: 5, block: "p", group_number: 13, color: 0xC0C0C0, description: "Weiches Metall. Für ITO-Touchscreens, Transistoren und Lötzinn.", theme: "semiconductor", experiments: ["touchscreen", "lötinn", "halbleiter"]},
    %{symbol: "Sn", name: "Zinn",             atomic_number: 50, mass: 118.71, group: :metal,         period: 5, block: "p", group_number: 14, color: 0xC0C0C0, description: "Historisch wichtiges Metall. Für Lötlegierungen und Bronze.", theme: "history", experiments: ["löten", "bronze", "konserven"]},
    %{symbol: "Sb", name: "Antimon",          atomic_number: 51, mass: 121.76, group: :metalloid,     period: 5, block: "p", group_number: 15, color: 0xC0C0C0, description: "Halbmetall mit ungewöhnlichen Eigenschaften.", theme: "industry", experiments: ["flammhemmer", "legierung", "halbleiter"]},
    %{symbol: "Te", name: "Tellur",           atomic_number: 52, mass: 127.60, group: :metalloid,     period: 5, block: "p", group_number: 16, color: 0xC0C0C0, description: "Seltenes Halbmetall. Für Solarzellen und Legierungen.", theme: "semiconductor", experiments: ["solarzelle", "legierung", "cdte"]},
    %{symbol: "I",  name: "Jod",              atomic_number: 53, mass: 126.90, group: :halogen,       period: 5, block: "p", group_number: 17, color: 0x00FF00, description: "Wichtiges Spurenelement für Schilddrüse.", theme: "biological", experiments: ["schilddrüse", "antiseptik", "sublimation"]},
    %{symbol: "Xe", name: "Xenon",            atomic_number: 54, mass: 131.29, group: :nobleGas,      period: 5, block: "p", group_number: 18, color: 0x00BFFF, description: "Schweres Edelgas. Für Ionentriebwerke und Narkose.", theme: "space", experiments: ["ionentrieb", "narkose", "laser"]},
    %{symbol: "Cs", name: "Cäsium",           atomic_number: 55, mass: 132.91, group: :alkali,        period: 6, block: "s", group_number: 1,  color: 0xFF6B6B, description: "Schmilzt in der Hand. Präzisestes Zeitnormal (Atomuhr).", theme: "precision", experiments: ["schmelzen", "atomuhr", "explosion"]},
    %{symbol: "Ba", name: "Barium",           atomic_number: 56, mass: 137.33, group: :alkalineEarth,  period: 6, block: "s", group_number: 2,  color: 0xE8D5B7, description: "Für medizinische Kontrastmittel und grüne Feuerwerke.", theme: "medical", experiments: ["kontrastmittel", "feuerwerk", "magnet"]},
    %{symbol: "La", name: "Lanthan",          atomic_number: 57, mass: 138.91, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Weiches, duktiles Metall. Für Hybridauto-Batterien und Zündsteine.", theme: "technology", experiments: ["batterie", "zündsteine", "optik"]},
    %{symbol: "Ce", name: "Cer",              atomic_number: 58, mass: 140.12, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Häufigstes Lanthanoid. Für Ferrocer-Feuerzeuge und Autokatalysatoren.", theme: "technology", experiments: ["feuerzeuge", "katalysator", "selbstreinigend"]},
    %{symbol: "Pr", name: "Praseodym",        atomic_number: 59, mass: 140.91, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Für Magnetlegierungen und grüne Farbe.", theme: "technology", experiments: ["magnet", "grün", "legierung"]},
    %{symbol: "Nd", name: "Neodym",           atomic_number: 60, mass: 144.24, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Stärkste Permanentmagnete. Für Kopfhörer und Windturbinen.", theme: "technology", experiments: ["magnet", "kopfhörer", "windturbine"]},
    %{symbol: "Pm", name: "Promethium",       atomic_number: 61, mass: 145.0,  group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Künstliches, radioaktives Element. Für Kernbatterien in Raumfahrzeugen.", theme: "space", experiments: ["künstlich", "kernbatterie", "radioaktiv"]},
    %{symbol: "Sm", name: "Samarium",         atomic_number: 62, mass: 150.36, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Für Permanentmagnete und Kernreaktor-Steuerstäbe.", theme: "nuclear", experiments: ["magnet", "reaktor", "absorber"]},
    %{symbol: "Eu", name: "Europium",         atomic_number: 63, mass: 151.96, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Rot phosphoreszierend in Euro-Scheinen.", theme: "security", experiments: ["phosphoreszenz", "euro", "laser"]},
    %{symbol: "Gd", name: "Gadolinium",       atomic_number: 64, mass: 157.25, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Höchste Neutronenabsorption. Für MRT-Kontrastmittel.", theme: "medical", experiments: ["mrt", "reaktor", "absorber"]},
    %{symbol: "Tb", name: "Terbium",          atomic_number: 65, mass: 158.93, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Weiches Lanthanoid. Für Phosphorleuchtstoffe.", theme: "technology", experiments: ["phosphor", "magnet", "motor"]},
    %{symbol: "Dy", name: "Dysprosium",       atomic_number: 66, mass: 162.50, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Hochwertiges Lanthanoid. Für Kernreaktorsteuerstäbe.", theme: "nuclear", experiments: ["reaktor", "magnet", "legierung"]},
    %{symbol: "Ho", name: "Holmium",          atomic_number: 67, mass: 164.93, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Höchstes magnetisches Moment aller Elemente.", theme: "technology", experiments: ["laser", "magnet", "hochleistung"]},
    %{symbol: "Er", name: "Erbium",           atomic_number: 68, mass: 167.26, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Für Glasfaser-Verstärker und optische Verstärker.", theme: "technology", experiments: ["glasfaser", "optik", "laser"]},
    %{symbol: "Tm", name: "Thulium",          atomic_number: 69, mass: 168.93, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Für medizinische Röntgenanlagen.", theme: "medical", experiments: ["röntgen", "medizin", "laser"]},
    %{symbol: "Yb", name: "Ytterbium",        atomic_number: 70, mass: 173.05, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Für Stahllegierungen und Röntgenanlagen.", theme: "industry", experiments: ["legierung", "röntgen", "luminiszenz"]},
    %{symbol: "Lu", name: "Lutetium",         atomic_number: 71, mass: 174.97, group: :lanthanide,    period: 6, block: "f", group_number: 3,  color: 0xE0E0E0, description: "Letztes natürliches Lanthanoid. Für PET-Scanner.", theme: "technology", experiments: ["scanner", "katalysator", "spektrometer"]},
    %{symbol: "Hf", name: "Hafnium",          atomic_number: 72, mass: 178.49, group: :transition,     period: 6, block: "d", group_number: 4,  color: 0xC0C0C0, description: "Korrosionsbeständiges Metall. Für Reaktordruckbehälter.", theme: "nuclear", experiments: ["reaktor", "kernenergie", "legierung"]},
    %{symbol: "Ta", name: "Tantal",           atomic_number: 73, mass: 180.95, group: :transition,     period: 6, block: "d", group_number: 5,  color: 0xC0C0C0, description: "Extrem korrosionsbeständig. Für Kondensatoren.", theme: "electronics", experiments: ["kondensator", "elektronik", "korrosion"]},
    %{symbol: "W",  name: "Wolfram",          atomic_number: 74, mass: 183.84, group: :transition,     period: 6, block: "d", group_number: 6,  color: 0xC0C0C0, description: "Höchster Schmelzpunkt aller Elemente. Für Glühbirnen.", theme: "technology", experiments: ["glühbirne", "bearbeitung", "legierung"]},
    %{symbol: "Re", name: "Rhenium",          atomic_number: 75, mass: 186.21, group: :transition,     period: 6, block: "d", group_number: 7,  color: 0xC0C0C0, description: "Seltenes, hochschmelzendes Metall. Für Düsenläufer.", theme: "aerospace", experiments: ["düsenläufer", "hochtemperatur", "legierung"]},
    %{symbol: "Os", name: "Osmium",           atomic_number: 76, mass: 190.23, group: :transition,     period: 6, block: "d", group_number: 8,  color: 0xC0C0C0, description: "Dichtestes natürliches Element. Für Schreibspitzen.", theme: "technology", experiments: ["schreibspitzen", "implantat", "legierung"]},
    %{symbol: "Ir", name: "Iridium",          atomic_number: 77, mass: 192.22, group: :transition,     period: 6, block: "d", group_number: 9,  color: 0xC0C0C0, description: "Extrem korrosionsbeständiges Metall. Für Zündkerzen.", theme: "technology", experiments: ["zündkerzen", "elektroden", "legierung"]},
    %{symbol: "Pt", name: "Platin",           atomic_number: 78, mass: 195.08, group: :transition,     period: 6, block: "d", group_number: 10, color: 0xC0C0C0, description: "Edelmetall für Katalysatoren, Schmuck. Beständiger als Gold.", theme: "precious", experiments: ["katalysator", "schmuck", "legierung"]},
    %{symbol: "Au", name: "Gold",             atomic_number: 79, mass: 196.97, group: :transition,     period: 6, block: "d", group_number: 11, color: 0xC0C0C0, description: "Edelstes Metall. Einziges gelbes Metall (relativistische Effekte).", theme: "treasure", experiments: ["ductilität", "legierungen", "elektroplattierung"]},
    %{symbol: "Hg", name: "Quecksilber",      atomic_number: 80, mass: 200.59, group: :transition,     period: 6, block: "d", group_number: 12, color: 0xC0C0C0, description: "Einziges flüssiges Metall bei Raumtemperatur.", theme: "historical", experiments: ["flüssig", "thermometer", "alchemie"]},
    %{symbol: "Tl", name: "Thallium",         atomic_number: 81, mass: 204.38, group: :metal,         period: 6, block: "p", group_number: 13, color: 0xC0C0C0, description: "Giftiges, weiches Metall. Historisch in Mordfällen verwendet.", theme: "toxic", experiments: ["gift", "glasherstellung", "temperatur"]},
    %{symbol: "Pb", name: "Blei",             atomic_number: 82, mass: 207.2,  group: :metal,         period: 6, block: "p", group_number: 14, color: 0xC0C0C0, description: "Schwerstes stabiles Element. Für Akkus und Röntgenschutz.", theme: "history", experiments: ["akkus", "röntgen", "blei"]},
    %{symbol: "Bi", name: "Wismut",           atomic_number: 83, mass: 208.98, group: :metalloid,     period: 6, block: "p", group_number: 15, color: 0xC0C0C0, description: "Dichtes, schmelzendes Metall. Für Kosmetika.", theme: "medical", experiments: ["kosmetika", "schmiermittel", "röntgen"]},
    %{symbol: "Po", name: "Polonium",         atomic_number: 84, mass: 209.0,  group: :metalloid,     period: 6, block: "p", group_number: 16, color: 0xC0C0C0, description: "Hochradioaktiv. Historisch berühmt (Curie).", theme: "nuclear", experiments: ["alphastrahler", "radioaktiv", "wärmequelle"]},
    %{symbol: "At", name: "Astatin",          atomic_number: 85, mass: 210.0,  group: :halogen,       period: 6, block: "p", group_number: 17, color: 0x00FF00, description: "Seltenstes natürliches Element. Halbwertszeit ~8 Stunden.", theme: "research", experiments: ["forschung", "halbwertszeit", "instabil"]},
    %{symbol: "Rn", name: "Radon",            atomic_number: 86, mass: 222.0,  group: :nobleGas,      period: 6, block: "p", group_number: 18, color: 0x00BFFF, description: "Radionuklid, zweithäufigste Lungenkrebsursache.", theme: "radiation", experiments: ["radonmessung", "schutz", "zerfall"]},
    %{symbol: "Fr", name: "Francium",         atomic_number: 87, mass: 223.0,  group: :alkali,        period: 7, block: "s", group_number: 1,  color: 0xFF6B6B, description: "Instabil, radioaktiv. Nie makroskopisch beobachtet.", theme: "theoretical", experiments: ["instabil", "halbwertszeit", "theoretisch"]},
    %{symbol: "Ra", name: "Radium",           atomic_number: 88, mass: 226.0,  group: :alkalineEarth,  period: 7, block: "s", group_number: 2,  color: 0xE8D5B7, description: "Hochradioaktiv, luminiszierendes Metall.", theme: "historical", experiments: ["leuchten", "historisch", "radioaktiv"]},
    %{symbol: "Ac", name: "Actinium",         atomic_number: 89, mass: 227.0,  group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Namensgeber der Actinoide. Radioaktiv.", theme: "nuclear", experiments: ["urananreicherung", "strahlung", "zerfall"]},
    %{symbol: "Th", name: "Thorium",          atomic_number: 90, mass: 232.04, group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Für Flüssigsalzreaktoren. Sicherer als Uran.", theme: "nuclear", experiments: ["flüssigsalzreaktor", "sicherheit", "kernenergie"]},
    %{symbol: "Pa", name: "Protactinium",     atomic_number: 91, mass: 231.04, group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Seltenes, radioaktives Element.", theme: "research", experiments: ["forschung", "kernreaktor", "urananreicherung"]},
    %{symbol: "U",  name: "Uran",             atomic_number: 92, mass: 238.03, group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Schwerstes häufiges natürliches Element. Basis für Kernenergie.", theme: "nuclear", experiments: ["fission", "decay", "fluorescence"]},
    %{symbol: "Np", name: "Neptunium",        atomic_number: 93, mass: 237.0,  group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Künstliches Element. Für Plutonium-Herstellung.", theme: "nuclear", experiments: ["künstlich", "plutonium", "reaktor"]},
    %{symbol: "Pu", name: "Plutonium",        atomic_number: 94, mass: 244.0,  group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Tödlichste Substanz. Mikrogramm können töten.", theme: "nuclear", experiments: ["kernwaffen", "raumfahrt", "gefahr"]},
    %{symbol: "Am", name: "Americium",        atomic_number: 95, mass: 243.0,  group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Künstliches Element. Für Rauchdetektoren.", theme: "space", experiments: ["rauchdetektor", "h-bombe", "spuren"]},
    %{symbol: "Cm", name: "Curium",           atomic_number: 96, mass: 247.0,  group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Künstliches Element. Für Raumschiff-RTGs.", theme: "space", experiments: ["raumfahrt", "curie", "kernenergie"]},
    %{symbol: "Bk", name: "Berkelium",        atomic_number: 97, mass: 247.0,  group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Künstliches Element. Sehr kurzlebig.", theme: "research", experiments: ["forschung", "kernchemie", "instabil"]},
    %{symbol: "Cf", name: "Californium",      atomic_number: 98, mass: 251.0,  group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Künstliches Element. Für Neutronenquellen.", theme: "nuclear", experiments: ["neutronenquelle", "synthese", "zerfall"]},
    %{symbol: "Es", name: "Einsteinium",      atomic_number: 99, mass: 252.0,  group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Künstliches Element. Entdeckt 1952 im H-Bomben-Fallout.", theme: "history", experiments: ["historisch", "h-bombe", "memorial"]},
    %{symbol: "Fm", name: "Fermium",          atomic_number: 100, mass: 257.0, group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Enrico Fermi.", theme: "research", experiments: ["reaktor", "theoretisch", "nuklearphysik"]},
    %{symbol: "Md", name: "Mendelevium",      atomic_number: 101, mass: 258.0, group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Mendelejew.", theme: "history", experiments: ["historisch", "periodensystem", "tradition"]},
    %{symbol: "No", name: "Nobelium",         atomic_number: 102, mass: 259.0, group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Künstliches Element. Benannt nach Alfred Nobel.", theme: "history", experiments: ["auszeichnung", "nobelpreis", "forschung"]},
    %{symbol: "Lr", name: "Lawrencium",       atomic_number: 103, mass: 262.0, group: :actinide,      period: 7, block: "f", group_number: 3,  color: 0xD0D0D0, description: "Letztes natürliches Element. Namensgeber: Ernest Lawrence.", theme: "discovery", experiments: ["entdeckung", "synchrotron", "teilchenbeschleuniger"]},
    %{symbol: "Rf", name: "Rutherfordium",    atomic_number: 104, mass: 267.0, group: :actinide,      period: 7, block: "d", group_number: 4,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Ernest Rutherford.", theme: "research", experiments: ["kernphysik", "teilchen", "reaktor"]},
    %{symbol: "Db", name: "Dubnium",          atomic_number: 105, mass: 268.0, group: :actinide,      period: 7, block: "d", group_number: 5,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Stadt Dubna.", theme: "research", experiments: ["forschung", "kernchemie", "instabil"]},
    %{symbol: "Sg", name: "Seaborgium",       atomic_number: 106, mass: 269.0, group: :actinide,      period: 7, block: "d", group_number: 6,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Glenn Seaborg.", theme: "research", experiments: ["forschung", "chemie", "synthese"]},
    %{symbol: "Bh", name: "Bohrium",          atomic_number: 107, mass: 270.0, group: :actinide,      period: 7, block: "d", group_number: 7,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Niels Bohr.", theme: "science", experiments: ["quantenmechanik", "theoretisch", "modell"]},
    %{symbol: "Hs", name: "Hassium",          atomic_number: 108, mass: 277.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Hessen.", theme: "discovery", experiments: ["entdeckung", "deutsch", "teilchen"]},
    %{symbol: "Mt", name: "Meitnerium",       atomic_number: 109, mass: 278.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Lise Meitner.", theme: "history", experiments: ["kernspaltung", "uran", "geschichte"]},
    %{symbol: "Ds", name: "Darmstadtium",     atomic_number: 110, mass: 281.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Darmstadt. GSI Teilchenbeschleuniger.", theme: "research", experiments: ["teilchenbeschleuniger", "schwerionen", "synthese"]},
    %{symbol: "Rg", name: "Roentgenium",      atomic_number: 111, mass: 282.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Wilhelm Röntgen.", theme: "medical", experiments: ["röntgen", "medizin", "synthese"]},
    %{symbol: "Cn", name: "Copernicium",      atomic_number: 112, mass: 285.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Nikolaus Kopernikus.", theme: "history", experiments: ["astronomie", "revolution", "universum"]},
    %{symbol: "Nh", name: "Nihonium",         atomic_number: 113, mass: 286.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Japan.", theme: "research", experiments: ["synthese", "element", "forschung"]},
    %{symbol: "Fl", name: "Flerovium",        atomic_number: 114, mass: 289.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Georgij Flerow.", theme: "science", experiments: ["theoretisch", "modell", "stabilität"]},
    %{symbol: "Mc", name: "Moscovium",         atomic_number: 115, mass: 290.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Moskau.", theme: "history", experiments: ["dubios", "synthese", "wissenschaft"]},
    %{symbol: "Lv", name: "Livermorium",      atomic_number: 116, mass: 293.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: LLNL.", theme: "research", experiments: ["element116", "kernreaktor", "synthese"]},
    %{symbol: "Ts", name: "Tennessin",        atomic_number: 117, mass: 294.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Künstliches Element. Namensgeber: Tennessee.", theme: "research", experiments: ["superheavy", "inselfstabilität", "synthese"]},
    %{symbol: "Og", name: "Oganesson",        atomic_number: 118, mass: 294.0, group: :actinide,      period: 7, block: "d", group_number: 8,  color: 0xD0D0D0, description: "Schwerstes bekanntes Element. Insel der Stabilität gesucht.", theme: "discovery", experiments: ["inselfstabilität", "insel", "theoretisch"]}
  ]

  @elements_by_symbol @elements |> Enum.reduce(%{}, fn e, acc -> Map.put(acc, e.symbol, e) end)
  @valid_symbols @elements |> Enum.map(& &1.symbol) |> MapSet.new()

  @doc """
  Returns all 118 element definitions.
  """
  @spec all_elements() :: [element()]
  def all_elements, do: @elements

  @doc """
  Returns the element for a given symbol, or nil.
  """
  @spec element_for_symbol(String.t()) :: element() | nil
  def element_for_symbol(symbol) when is_binary(symbol) do
    Map.get(@elements_by_symbol, symbol)
  end

  def element_for_symbol(_), do: nil

  @doc """
  Returns true if the given string is a valid element symbol.
  """
  @spec valid_element_symbol?(String.t()) :: boolean()
  def valid_element_symbol?(symbol) when is_binary(symbol) do
    MapSet.member?(@valid_symbols, symbol)
  end

  def valid_element_symbol?(_), do: false

  @doc """
  Validates chemistry user_data map.

  Expected shape:
    %{
      "symbol" => "H",            # required - valid element symbol
      "theme" => "cosmic",         # optional - visual theme name
      "experiments" => ["knallgas"]  # optional - list of experiment IDs
    }

  Returns `:ok` or `{:error, reason}`.
  """
  @spec validate_chemistry_data(map() | nil) :: :ok | {:error, String.t()}
  def validate_chemistry_data(nil), do: :ok

  def validate_chemistry_data(%{"symbol" => symbol} = data) when is_map(data) do
    cond do
      !valid_element_symbol?(symbol) ->
        {:error, "Invalid element symbol: #{symbol}"}

      true ->
        :ok
    end
  end

  def validate_chemistry_data(%{symbol: symbol} = data) when is_map(data) do
    validate_chemistry_data(%{"symbol" => symbol})
  end

  def validate_chemistry_data(_), do: {:error, "Chemistry data must contain a 'symbol' field"}

  @doc """
  Returns all valid element groups.
  """
  @spec valid_groups() :: [element_group()]
  def valid_groups, do: @valid_groups
end
