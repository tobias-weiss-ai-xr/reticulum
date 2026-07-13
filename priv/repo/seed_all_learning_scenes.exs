# Seed all chemistry learning scenes.
# Run with: mix run priv/repo/seed_all_learning_scenes.exs
#
# This creates Scene + SceneListing records for each chemistry element (118 total).
# Available GLBs: molecule files (h2, ch4, co2, n2, o2, nh3, nacl, h2o) + per-element atom GLBs.

alias Ret.{Repo, Scene, SceneListing, Storage, OwnedFile, Account}
import Ecto.Query

account =
  Ret.Account
  |> where([a], a.is_admin == true and a.state == :enabled)
  |> limit(1)
  |> Repo.one!()

IO.puts("Seeding chemistry learning scenes for account ##{account.account_id}")
IO.puts("")

# Elements that have molecule GLB representations (symbol -> molecule_key, filename, scene_name_suffix)
molecules = %{
  "H"  => {nil, "h2.glb", " - H2"},
  "C"  => {"ch4", "ch4.glb", " - CH4 (Methan)"},
  "N"  => {"n2", "n2.glb", " - N2"},
  "O"  => {"o2", "o2.glb", " - O2"},
  "Na" => {"nacl", "nacl.glb", " - NaCl (Kochsalz)"},
  "Cl" => {"nacl", "nacl.glb", " - NaCl (Kochsalz)"},
  "Fe" => {"fe", "fe.glb", " (Fe-Atom)"},
  "Cu" => {"cu", "cu.glb", " (Cu-Atom)"},
  "Au" => {"au", "au.glb", " (Au-Atom)"},
  "Ag" => {"ag", "ag.glb", " (Ag-Atom)"}
}

# Descriptive mapping for the learning scene naming
element_desc = %{
  "H"  => "Das häufigste Element im Universum. Treibstoff der Sterne, Baustein des Wassers.",
  "He" => "Das zweithäufigste Element im Universum. Leichter als Luft, macht Ballons schweben.",
  "Li" => "Leichtestes Metall. Wichtig für Akkus und Batterien.",
  "Be" => "Hochgiftiges Metall mit niedriger Dichte. Verwendet in der Weltraumtechnik.",
  "B"  => "Hartes Material für Glasfasern. Kommt in Wüstensalzen vor.",
  "C"  => "Das Element des Lebens. Grundbaustein aller organischen Verbindungen.",
  "N"  => "Macht 78% der Atmosphäre aus. Essentiell für Proteine und DNA.",
  "O"  => "Notwendig für Atmung und Verbrennung. Zweithäufigstes Element im Universum.",
  "F"  => "Reaktivstes aller Elemente. Wird in Teflon und Zahncreme verwendet.",
  "Ne" => "Leuchtet bei elektrischer Entladung orange-rot. Symbol der Stadtbeleuchtung.",
  "Na" => "Silberglänzendes Metall, butterweich. Basis für Speisesalz (NaCl).",
  "Mg" => "Blendend weißes Licht beim Verbrennen. Kommt in Chlorophyll vor.",
  "Al" => "Das häufigste Metall der Erdkruste. Leicht und korrosionsbeständig.",
  "Si" => "Zweithäufigstes Element der Erdkruste. Basis aller modernen Elektronik.",
  "P"  => "Glüht weiß im Dunkeln. Wichtiger Bestandteil von DNA und ATP.",
  "S"  => "Gelbes Element mit charakteristischem Geruch. Kommt in Vulkanen vor.",
  "Cl" => "Grün-gelbes Giftgas. Wird zur Wasserdesinfektion verwendet.",
  "Ar" => "Häufigstes Edelgas (1% Atmosphäre). Wird für WIG-Schweißen verwendet.",
  "K"  => "Reaktives Metall, in Natur oft als Ion. Wesentlich für biologische Prozesse.",
  "Ca" => "Fünft-häufigstes Element der Erdkruste. Wichtig für Knochen und Zähne.",
  "Sc" => "Seltenes Übergangsmetall. Wird in Sportgeräten verwendet.",
  "Ti" => "Korrosionsbeständiges Metall. Für Luft- und Raumfahrtindustrie.",
  "V"  => "Hartes, grau-weißes Metall. Für Werkzeugstahl und Legierungen.",
  "Cr" => "Glänzendes, korrosionsbeständiges Metall. Basis von Edelstahl.",
  "Mn" => "Wichtig für Stahlherstellung. Bioelement für Photosynthese.",
  "Fe" => "Wichtigstes Metall der Menschheit. Grundbaustein von Stahl und Hämoglobin.",
  "Co" => "Blau-graues, ferromagnetisches Metall. Für Supraleiter, Magnete und Batterien.",
  "Ni" => "Silbrig-weißes, korrosionsbeständiges Metall. Münzmetall.",
  "Cu" => "Erstes Metall der Menschheit. Exzellenter elektrischer Leiter.",
  "Zn" => "Reaktionsfreies Metall. Für galvanische Zellen und Verzinkung.",
  "Ga" => "Schmilzt in der Hand bei Raumtemperatur. Für Halbleiter.",
  "Ge" => "Halbleiter für Transistoren und Optoelektronik.",
  "As" => "Sehr giftiges Halbmetall. Historisch in Tapeten verwendet.",
  "Se" => "Wichtiges Spurenelement. Halbleiter und für Glühbirnen.",
  "Br" => "Einziges flüssiges Nichtmetall bei Raumtemperatur.",
  "Kr" => "Edelgas mit hoher Dichte. Für Blitzlichtlampen und Laser.",
  "Rb" => "Weiches, hochreaktives Metall. Für Atomuhren und Feuerwerk.",
  "Sr" => "Für rote Feuerwerke und Magnete.",
  "Y"  => "Seltenes Erdelement. Für LEDs, Supraleiter und Laser.",
  "Zr" => "Korrosionsbeständiges Metall. Für Kernelemente.",
  "Nb" => "Supraleiter bei niedrigen Temperaturen.",
  "Mo" => "Extrem hartes Metall. Für Hochtemperaturanwendungen.",
  "Tc" => "Erstes künstliches Element. Radioaktiv. In der medizinischen Bildgebung.",
  "Ru" => "Seltenes Metall. Für Elektronikkontakte und Katalysatoren.",
  "Rh" => "Sehr wertvolles Übergangsmetall. Für Katalysatoren.",
  "Pd" => "Wertvolles Platin-Metall. Für Katalysatoren und Schmuck.",
  "Ag" => "Bester elektrischer Leiter aller Metalle.",
  "Cd" => "Giftiges Metall. Für NiCd-Batterien und Pigmente.",
  "In" => "Weiches Metall. Für ITO-Touchscreens und Transistoren.",
  "Sn" => "Historisch wichtiges Metall. Für Lötlegierungen und Bronze.",
  "Sb" => "Halbmetall mit ungewöhnlichen Eigenschaften.",
  "Te" => "Seltenes Halbmetall. Für Solarzellen und Legierungen.",
  "I"  => "Wichtiges Spurenelement für die Schilddrüse.",
  "Xe" => "Schweres Edelgas. Für Ionentriebwerke und Narkose.",
  "Cs" => "Schmilzt in der Hand. Präzisestes Zeitnormal (Atomuhr).",
  "Ba" => "Für medizinische Kontrastmittel und grüne Feuerwerke.",
  "La" => "Weiches, duktiles Metall. Für Hybridauto-Batterien.",
  "Ce" => "Häufigstes Lanthanoid. Für Feuerzeuge und Autokatalysatoren.",
  "Pr" => "Für Magnetlegierungen und grüne Farbe.",
  "Nd" => "Stärkste Permanentmagnete. Für Kopfhörer und Windturbinen.",
  "Pm" => "Künstliches, radioaktives Element. Für Kernbatterien.",
  "Sm" => "Für Permanentmagnete und Reaktor-Steuerstäbe.",
  "Eu" => "Rot phosphoreszierend in Euro-Scheinen.",
  "Gd" => "Höchste Neutronenabsorption. Für MRT-Kontrastmittel.",
  "Tb" => "Weiches Lanthanoid. Für Phosphorleuchtstoffe.",
  "Dy" => "Hochwertiges Lanthanoid. Für Reaktorsteuerstäbe.",
  "Ho" => "Höchstes magnetisches Moment aller Elemente.",
  "Er" => "Für Glasfaser-Verstärker und optische Verstärker.",
  "Tm" => "Für medizinische Röntgenanlagen.",
  "Yb" => "Für Stahllegierungen und Röntgenanlagen.",
  "Lu" => "Letztes natürliches Lanthanoid. Für PET-Scanner.",
  "Hf" => "Korrosionsbeständiges Metall. Für Reaktordruckbehälter.",
  "Ta" => "Extrem korrosionsbeständig. Für Kondensatoren.",
  "W"  => "Höchster Schmelzpunkt aller Elemente. Für Glühbirnen.",
  "Re" => "Seltenes, hochschmelzendes Metall. Für Düsenläufer.",
  "Os" => "Dichtestes natürliches Element. Für Schreibspitzen.",
  "Ir" => "Extrem korrosionsbeständiges Metall. Für Zündkerzen.",
  "Pt" => "Edelmetall für Katalysatoren und Schmuck.",
  "Au" => "Edelstes Metall. Einziges gelbes Metall (relativistische Effekte).",
  "Hg" => "Einziges flüssiges Metall bei Raumtemperatur.",
  "Tl" => "Giftiges, weiches Metall. Historisch in Mordfällen verwendet.",
  "Pb" => "Schwerstes stabiles Element. Für Akkus und Röntgenschutz.",
  "Bi" => "Dichtes, schmelzendes Metall. Für Kosmetika.",
  "Po" => "Hochradioaktiv. Historisch berühmt (Curie).",
  "At" => "Seltenstes natürliches Element. Halbwertszeit ~8 Stunden.",
  "Rn" => "Radionuklid, zweithäufigste Lungenkrebsursache.",
  "Fr" => "Instabil, radioaktiv. Nie makroskopisch beobachtet.",
  "Ra" => "Hochradioaktiv, lumineszierendes Metall.",
  "Ac" => "Namensgeber der Actinoide. Radioaktiv.",
  "Th" => "Für Flüssigsalzreaktoren. Sicherer als Uran.",
  "Pa" => "Seltenes, radioaktives Element.",
  "U"  => "Schwerstes häufiges natürliches Element. Basis für Kernenergie.",
  "Np" => "Künstliches Element. Für Plutonium-Herstellung.",
  "Pu" => "Tödlichste bekannte Substanz.",
  "Am" => "Künstliches Element. Für Rauchdetektoren.",
  "Cm" => "Künstliches Element. Für Raumschiff-RTGs.",
  "Bk" => "Künstliches Element. Sehr kurzlebig.",
  "Cf" => "Künstliches Element. Für Neutronenquellen.",
  "Es" => "Künstliches Element. Entdeckt 1952 im H-Bomben-Fallout.",
  "Fm" => "Künstliches Element. Namensgeber: Enrico Fermi.",
  "Md" => "Künstliches Element. Namensgeber: Mendelejew.",
  "No" => "Künstliches Element. Benannt nach Alfred Nobel.",
  "Lr" => "Letztes natürliches Element. Namensgeber: Ernest Lawrence.",
  "Rf" => "Künstliches Element. Namensgeber: Ernest Rutherford.",
  "Db" => "Künstliches Element. Namensgeber: Stadt Dubna.",
  "Sg" => "Künstliches Element. Namensgeber: Glenn Seaborg.",
  "Bh" => "Künstliches Element. Namensgeber: Niels Bohr.",
  "Hs" => "Künstliches Element. Namensgeber: Hessen.",
  "Mt" => "Künstliches Element. Namensgeber: Lise Meitner.",
  "Ds" => "Künstliches Element. Namensgeber: Darmstadt.",
  "Rg" => "Künstliches Element. Namensgeber: Wilhelm Röntgen.",
  "Cn" => "Künstliches Element. Namensgeber: Kopernikus.",
  "Nh" => "Künstliches Element. Namensgeber: Japan.",
  "Fl" => "Künstliches Element. Namensgeber: Georgij Flerow.",
  "Mc" => "Künstliches Element. Namensgeber: Moskau.",
  "Lv" => "Künstliches Element. Namensgeber: LLNL.",
  "Ts" => "Künstliches Element. Namensgeber: Tennessee.",
  "Og" => "Schwerstes bekanntes Element. Insel der Stabilität gesucht."
}

# German names for all elements
element_names = %{
  "H"  => "Wasserstoff", "He" => "Helium", "Li" => "Lithium", "Be" => "Beryllium",
  "B"  => "Bor", "C" => "Kohlenstoff", "N" => "Stickstoff", "O" => "Sauerstoff",
  "F"  => "Fluor", "Ne" => "Neon", "Na" => "Natrium", "Mg" => "Magnesium",
  "Al" => "Aluminium", "Si" => "Silizium", "P" => "Phosphor", "S" => "Schwefel",
  "Cl" => "Chlor", "Ar" => "Argon", "K" => "Kalium", "Ca" => "Calcium",
  "Sc" => "Scandium", "Ti" => "Titan", "V" => "Vanadium", "Cr" => "Chrom",
  "Mn" => "Mangan", "Fe" => "Eisen", "Co" => "Kobalt", "Ni" => "Nickel",
  "Cu" => "Kupfer", "Zn" => "Zink", "Ga" => "Gallium", "Ge" => "Germanium",
  "As" => "Arsen", "Se" => "Selen", "Br" => "Brom", "Kr" => "Krypton",
  "Rb" => "Rubidium", "Sr" => "Strontium", "Y" => "Yttrium", "Zr" => "Zirkonium",
  "Nb" => "Niob", "Mo" => "Molybdän", "Tc" => "Technetium", "Ru" => "Ruthenium",
  "Rh" => "Rhodium", "Pd" => "Palladium", "Ag" => "Silber", "Cd" => "Cadmium",
  "In" => "Indium", "Sn" => "Zinn", "Sb" => "Antimon", "Te" => "Tellur",
  "I"  => "Jod", "Xe" => "Xenon", "Cs" => "Cäsium", "Ba" => "Barium",
  "La" => "Lanthan", "Ce" => "Cer", "Pr" => "Praseodym", "Nd" => "Neodym",
  "Pm" => "Promethium", "Sm" => "Samarium", "Eu" => "Europium", "Gd" => "Gadolinium",
  "Tb" => "Terbium", "Dy" => "Dysprosium", "Ho" => "Holmium", "Er" => "Erbium",
  "Tm" => "Thulium", "Yb" => "Ytterbium", "Lu" => "Lutetium", "Hf" => "Hafnium",
  "Ta" => "Tantal", "W" => "Wolfram", "Re" => "Rhenium", "Os" => "Osmium",
  "Ir" => "Iridium", "Pt" => "Platin", "Au" => "Gold", "Hg" => "Quecksilber",
  "Tl" => "Thallium", "Pb" => "Blei", "Bi" => "Wismut", "Po" => "Polonium",
  "At" => "Astatin", "Rn" => "Radon", "Fr" => "Francium", "Ra" => "Radium",
  "Ac" => "Actinium", "Th" => "Thorium", "Pa" => "Protactinium", "U" => "Uran",
  "Np" => "Neptunium", "Pu" => "Plutonium", "Am" => "Americium", "Cm" => "Curium",
  "Bk" => "Berkelium", "Cf" => "Californium", "Es" => "Einsteinium", "Fm" => "Fermium",
  "Md" => "Mendelevium", "No" => "Nobelium", "Lr" => "Lawrencium",
  "Rf" => "Rutherfordium", "Db" => "Dubnium", "Sg" => "Seaborgium",
  "Bh" => "Bohrium", "Hs" => "Hassium", "Mt" => "Meitnerium",
  "Ds" => "Darmstadtium", "Rg" => "Roentgenium", "Cn" => "Copernicium",
  "Nh" => "Nihonium", "Fl" => "Flerovium", "Mc" => "Moscovium",
  "Lv" => "Livermorium", "Ts" => "Tennessin", "Og" => "Oganesson"
}

# Build element definitions for all 118
all_symbols = ~w(
  H He Li Be B C N O F Ne Na Mg Al Si P S Cl Ar K Ca
  Sc Ti V Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr
  Rb Sr Y Zr Nb Mo Tc Ru Rh Pd Ag Cd In Sn Sb Te I Xe
  Cs Ba La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu
  Hf Ta W Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn
  Fr Ra Ac Th Pa U Np Pu Am Cm Bk Cf Es Fm Md No Lr
  Rf Db Sg Bh Hs Mt Ds Rg Cn Nh Fl Mc Lv Ts Og
)

elements = Enum.map(all_symbols, fn sym ->
  name = element_names[sym] || sym
  scene_name_base = "#{name} (#{sym})"
  {molecule_key, filename, suffix} = Map.get(molecules, sym, {sym, "#{String.downcase(sym)}.glb", " (Atom)"})
  desc = element_desc[sym] || "Interaktive 3D-Lernszene fuer das Element #{name} (#{sym})."

  %{
    symbol: sym,
    name: name,
    scene_name: scene_name_base <> suffix,
    description: desc,
    filename: filename,
    molecule_key: molecule_key || String.downcase(sym),
    slug: "#{String.downcase(sym)}-#{String.downcase(name)}" |> String.normalize(:nfd) |> String.replace(~r/[^a-z0-9-]/, ""),
    tags: ["learning", String.downcase(sym)]
  }
end)

IO.puts("Total elements to seed: #{length(elements)}")
IO.puts("")

total_created = 0
total_skipped = 0

for el <- elements do
  existing =
    Scene
    |> Repo.get_by(name: el.scene_name)
    |> Repo.preload(Scene.scene_preloads())

  if existing do
    IO.puts("  [#{el.symbol}] Scene '#{el.scene_name}' already exists (##{existing.scene_id}), skipping.")

    unless Repo.get_by(SceneListing, scene_id: existing.scene_id) do
      {:ok, _listing} =
        %SceneListing{}
        |> SceneListing.changeset_for_listing_for_scene(existing, %{
          slug: el.slug,
          tags: %{tags: el.tags}
        })
        |> Repo.insert()

      IO.puts("    -> SceneListing created with tags: #{Enum.join(el.tags, ", ")}")
    end

    total_skipped = total_skipped + 1
  else
    glb_path = Path.expand("../../learning-scenes/#{el.filename}", __DIR__)

    unless File.exists?(glb_path) do
      IO.puts("ERROR: #{glb_path} not found for element #{el.symbol}!")
      System.halt(1)
    end

    content_length = File.stat!(glb_path).size
    IO.puts("  [#{el.symbol}] Reading #{el.filename} (#{content_length} bytes)...")

    model_key = SecureRandom.hex()
    {:ok, model_uuid} = Storage.store(glb_path, "model/gltf-binary", model_key, nil, Storage.owned_file_path())

    model_owned_file =
      %OwnedFile{}
      |> OwnedFile.changeset(account, %{
        owned_file_uuid: model_uuid,
        key: model_key,
        content_type: "model/gltf-binary",
        content_length: content_length
      })
      |> Repo.insert!()

    IO.puts("    -> Model OwnedFile ##{model_owned_file.owned_file_id} created")

    # Minimal 1x1 PNG as screenshot
    minimal_png =
      :binary.list_to_bin([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
        0x54, 0x08, 0xD7, 0x63, 0xD8, 0xAC, 0x51, 0x00,
        0x00, 0x00, 0x28, 0x00, 0x01, 0x81, 0x3E, 0xA4,
        0xF3, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
        0x44, 0xAE, 0x42, 0x60, 0x82
      ])

    screenshot_path = Path.expand("../../learning-scenes/screenshot_#{el.molecule_key}.png", __DIR__)
    File.write!(screenshot_path, minimal_png)

    screenshot_key = SecureRandom.hex()
    {:ok, screenshot_uuid} =
      Storage.store(screenshot_path, "image/png", screenshot_key, nil, Storage.owned_file_path())

    screenshot_owned_file =
      %OwnedFile{}
      |> OwnedFile.changeset(account, %{
        owned_file_uuid: screenshot_uuid,
        key: screenshot_key,
        content_type: "image/png",
        content_length: File.stat!(screenshot_path).size
      })
      |> Repo.insert!()

    IO.puts("    -> Screenshot OwnedFile ##{screenshot_owned_file.owned_file_id} created")

    {:ok, scene} =
      %Scene{}
      |> Scene.changeset(account, model_owned_file, screenshot_owned_file, nil, %{
        name: el.scene_name,
        description: el.description,
        allow_remixing: true,
        allow_promotion: true,
        attributions: %{"extras" => "Generated with hubs-compose molecule generator"}
      })
      |> Repo.insert()

    scene = Repo.preload(scene, Scene.scene_preloads())
    IO.puts("    -> Scene ##{scene.scene_id} created: '#{scene.name}'")

    {:ok, _listing} =
      %SceneListing{}
      |> SceneListing.changeset_for_listing_for_scene(scene, %{
        slug: el.slug,
        tags: %{tags: el.tags}
      })
      |> Repo.insert()

    IO.puts("    -> SceneListing created with tags: #{Enum.join(el.tags, ", ")}")

    # Cleanup temp screenshot
    File.rm!(screenshot_path)

    total_created = total_created + 1
  end

  IO.puts("")
end

IO.puts("Done! #{total_created} scenes created, #{total_skipped} skipped.")
