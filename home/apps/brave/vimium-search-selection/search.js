// ---- Eigener Vimium-Befehl "searchSelection" (eingebaut über home/apps/brave/default.nix) ----
// Wie Surfingkeys' "s" + Suchmaschine. Kleinbuchstabe = neuer Tab, Großbuchstabe = aktueller Tab.
//  * Normal-Mode: s, dann Taste → sucht die Markierung oder den zuletzt kopierten Text (y, yy …)
//  * Visual-/Caret-Mode: sg, sd, … direkt → sucht die aktuelle Markierung
(() => {
  // Kürzel → [Name, Such-URL]; hier einfach Einträge ergänzen oder ändern
  const ENGINES = {
    g: ["Google", "https://www.google.com/search?q="],
    d: ["DuckDuckGo", "https://duckduckgo.com/?q="],
    h: ["GitHub", "https://github.com/search?q="],
    y: ["YouTube", "https://www.youtube.com/results?search_query="],
    e: ["Wikipedia", "https://de.wikipedia.org/w/index.php?search="],
    s: ["StackOverflow", "https://stackoverflow.com/search?q="],
    n: ["Nix-Pakete", "https://search.nixos.org/packages?query="],
    o: ["NixOS-Optionen", "https://search.nixos.org/options?query="],
    m: ["Home-Manager", "https://home-manager-options.extranix.com/?query="],
  };

  // lastCopiedText setzt der Clipboard-Fix in vimium-visual-hints/picker.js
  const lastCopied = () => (HUD.lastCopiedText || "").trim();

  function search(text, key, newTab) {
    const engine = ENGINES[key];
    const query = (text || "").replace(/\s+/g, " ").trim();
    if (!engine) return; // unbekannte Taste = abbrechen
    if (!query) { HUD.show("Nichts markiert oder kopiert", 1500); return; }
    chrome.runtime.sendMessage({
      handler: newTab ? "openUrlInNewTab" : "openUrlInCurrentTab",
      url: engine[1] + encodeURIComponent(query),
      count: 1, // Vimiums Tab-Handler erwartet einen count
    });
  }

  // Normal-Mode: "s", dann Suchmaschinen-Taste
  NormalModeCommands.searchSelection = function () {
    const text = getSelection().toString().trim() || lastCopied();
    if (!text) { HUD.show("Nichts markiert oder kopiert", 1500); return; }

    const short = text.replace(/\s+/g, " ");
    const preview = short.length > 25 ? short.slice(0, 22) + "…" : short;
    const list = Object.entries(ENGINES).map(([k, [name]]) => `${k} ${name}`).join(" · ");
    HUD.show(`„${preview}“ suchen: ${list}`);

    const mode = new Mode();
    mode.init({
      name: "search-selection",
      indicator: false,
      exitOnEscape: true,
      suppressAllKeyboardEvents: true,
      keydown: (event) => {
        const ch = KeyboardUtils.getKeyChar(event);
        if (!ch || ch.length !== 1) return; // Shift allein usw. ignorieren
        mode.exit();
        search(text, ch.toLowerCase(), ch === ch.toLowerCase());
      },
    });
    mode.onExit(() => HUD.hide());
  };

  // Visual-/Visual-Line-/Caret-Mode: sg, sG, sd, sD, … in Vimiums eigene Tabelle eintragen.
  // (Die Tabelle wird bei jedem Start des Visual-Modes gelesen; mode_visual.js ist da schon geladen.)
  for (const key of Object.keys(ENGINES)) {
    for (const [k, newTab] of [[key, true], [key.toUpperCase(), false]]) {
      VisualMode.prototype.movements["s" + k] = function () {
        const text = this.selection.toString().trim() || lastCopied();
        this.exit();
        search(text, key, newTab);
      };
    }
  }
})();
