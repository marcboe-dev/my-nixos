// ---- Eigener Vimium-Befehl "visualHints" (eingebaut über home/apps/brave/default.nix) ----
// Wie Surfingkeys' "v": Hints auf jedem sichtbaren Wort, nach Auswahl steht der Cursor dort
// im Caret-Mode. Danach: hjkl/w/b/e/0/$ bewegen, v = markieren, y = kopieren,
// p/P = Auswahl öffnen/suchen, Esc = beenden.
// Gibt es schon eine Markierung (z.B. mit der Maus), startet direkt Vimiums normaler Visual-Mode.
(() => {
  const SKIP = new Set(["SCRIPT", "STYLE", "NOSCRIPT", "TEXTAREA", "TEMPLATE"]);
  const WORD = /[\p{L}\p{N}_]+/gu; // Wortanfänge, inkl. Umlaute
  const inView = (r) => r.width > 0 && r.height > 0 && r.bottom > 0 && r.right > 0 &&
    r.top < innerHeight && r.left < innerWidth;
  const hintChars = () =>
    [...new Set((Settings.get("linkHintCharacters") || "sadfjklewcmpgh").toLowerCase())];

  function findWords(max) {
    const words = [];
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
      acceptNode(node) {
        const el = node.parentElement;
        if (!el || !node.data.trim() || SKIP.has(el.tagName) || el.isContentEditable) return NodeFilter.FILTER_REJECT;
        if (!inView(el.getBoundingClientRect())) return NodeFilter.FILTER_REJECT; // billiger Vorfilter
        if (el.checkVisibility && !el.checkVisibility({ visibilityProperty: true, opacityProperty: true })) return NodeFilter.FILTER_REJECT;
        return NodeFilter.FILTER_ACCEPT;
      },
    });
    const range = document.createRange();
    let node;
    while ((node = walker.nextNode())) {
      WORD.lastIndex = 0;
      let m;
      while ((m = WORD.exec(node.data))) {
        range.setStart(node, m.index);
        range.setEnd(node, m.index + 1);
        const r = range.getClientRects()[0];
        if (!r) continue;
        if (r.top >= innerHeight) break; // Rest des Textknotens liegt unterhalb
        if (!inView(r)) continue;
        words.push({ node, offset: m.index, x: r.left, y: r.top });
        if (words.length >= max) return words;
      }
    }
    return words;
  }

  // Gleich lange Labels → kein Label ist Präfix eines anderen
  function makeLabels(n, chars) {
    let len = 1;
    while (chars.length ** len < n) len++;
    const labels = [];
    for (let i = 0; i < n; i++) {
      let s = "", k = i;
      for (let j = 0; j < len; j++) { s += chars[k % chars.length]; k = Math.floor(k / chars.length); }
      labels.push(s);
    }
    return labels;
  }

  function drawOverlay(words) {
    const overlay = document.createElement("div");
    overlay.style.cssText = "position:fixed;inset:0;z-index:2147483647;pointer-events:none;";
    const frag = document.createDocumentFragment();
    for (const w of words) {
      const el = document.createElement("div");
      el.textContent = w.label.toUpperCase();
      el.style.cssText = `position:fixed;left:${Math.max(w.x - 2, 0)}px;top:${Math.max(w.y - 2, 0)}px;` +
        "padding:0 2px;border-radius:2px;font:bold 11px/1.2 monospace;color:#1a1b26;" +
        "background:#e0af68;box-shadow:0 1px 2px rgba(0,0,0,.4);";
      w.el = el;
      frag.appendChild(el);
    }
    overlay.appendChild(frag);
    document.documentElement.appendChild(overlay);
    return overlay;
  }

  function placeCaret(word) {
    const active = document.activeElement;
    if (active && DomUtils.isEditable(active)) active.blur();
    const range = document.createRange();
    range.setStart(word.node, word.offset);
    range.collapse(true);
    const sel = getSelection();
    sel.removeAllRanges();
    sel.addRange(range);
    new CaretMode().init(); // Vimiums Caret-Mode übernimmt die vorhandene Cursor-Position
  }

  NormalModeCommands.visualHints = function () {
    if (getSelection().type === "Range") return NormalModeCommands.enterVisualMode();
    const chars = hintChars();
    const words = findWords(Math.min(chars.length ** 3, 2000));
    if (words.length === 0) { HUD.show("Kein sichtbarer Text gefunden", 1500); return; }
    if (words.length === 1) return placeCaret(words[0]);

    makeLabels(words.length, chars).forEach((l, i) => (words[i].label = l));
    const overlay = drawOverlay(words);
    let typed = "";

    const mode = new Mode();
    mode.init({
      name: "visual-hints",
      indicator: "Wort wählen",
      exitOnEscape: true,
      suppressAllKeyboardEvents: true,
      keydown: (event) => {
        if (event.key === "Backspace") typed = typed.slice(0, -1);
        else {
          const ch = KeyboardUtils.getKeyChar(event);
          if (!ch || ch.length !== 1) return;
          typed += ch.toLowerCase();
        }
        const matches = words.filter((w) => w.label.startsWith(typed));
        if (matches.length === 0) { mode.exit(); return; }
        if (matches.length === 1 && matches[0].label === typed) { mode.exit(); placeCaret(matches[0]); return; }
        for (const w of words) w.el.style.display = w.label.startsWith(typed) ? "" : "none";
      },
    });
    mode.onExit(() => overlay.remove());
  };
})();

// ---- Fix: Kopieren direkt aus der Seite statt über Vimiums HUD-iframe (y, yy, yf …) ----
// Vimiums Weg übers iframe scheitert in Brave manchmal: dann landet nichts in der
// Zwischenablage und der Fokus bleibt im unsichtbaren iframe hängen.
(() => {
  const original = HUD.copyToClipboard;

  // Fallback ohne Clipboard-API: unsichtbares Textfeld + execCommand("copy")
  const copyViaTextarea = (text) => {
    const prevFocus = document.activeElement;
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.setAttribute("readonly", "");
    ta.style.cssText = "position:fixed;top:0;left:0;width:1px;height:1px;opacity:0;pointer-events:none;";
    document.documentElement.appendChild(ta);
    ta.select();
    let ok = false;
    try { ok = document.execCommand("copy"); } catch (_) { ok = false; }
    ta.blur(); // sonst bleibt Vimium im Insert-Mode
    ta.remove();
    if (prevFocus && prevFocus !== document.body && prevFocus.focus) prevFocus.focus();
    return ok;
  };

  const refocusPage = (hud) => {
    const iframe = hud.hudUI && hud.hudUI.iframeElement;
    if (iframe && iframe.getRootNode().activeElement === iframe) {
      iframe.blur();
      globalThis.focus();
    }
  };

  HUD.copyToClipboard = async function (text) {
    const value = text.replace(/\xa0/g, " "); // wie Vimium: geschützte Leerzeichen → normale
    this.lastCopiedText = value; // ← neu: für searchSelection
    try {
      await navigator.clipboard.writeText(value); // 1. direkt aus der Seite
      return;
    } catch (_) {}
    if (copyViaTextarea(value)) return;           // 2. klassischer Weg
    await original.call(this, text);              // 3. Vimiums eigener Weg …
    for (const ms of [50, 200, 500, 1000]) setTimeout(() => refocusPage(this), ms); // … + Fokus retten
  };
})();
