// ---- Eigener Vimium-Befehl "pasteIntoInput" (eingebaut über home/apps/brave/default.nix) ----
// p im Normal-Mode: fokussiert das Feld, das gi wählen würde, und fügt die Zwischenablage ein.
// Text → wie Tippen; Bilder/Dateien → paste-Event (wie Strg+V), z.B. Satty-Screenshots.
(() => {
  // Liest Text + Dateien ohne Rückfrage: execCommand("paste") in ein verstecktes
  // contenteditable löst ein echtes paste-Event aus, dessen clipboardData wir abfangen.
  // Geht nur, weil die Extension "clipboardRead" hat (Manifest-Patch in default.nix).
  const readClipboard = () => {
    const box = document.createElement("div");
    box.contentEditable = "true";
    box.style.cssText = "position:fixed;top:0;left:0;width:1px;height:1px;opacity:0;" +
      "pointer-events:none;overflow:hidden;";
    document.documentElement.appendChild(box);
    let result = null;
    const onPaste = (e) => {
      e.preventDefault();
      e.stopImmediatePropagation(); // Seite soll dieses interne Einfügen nicht sehen
      const dt = e.clipboardData;
      result = {
        text: (dt.getData("text/plain") || "").replace(/\xa0/g, " "),
        files: [...dt.files],
      };
    };
    box.addEventListener("paste", onPaste, true);
    box.focus();
    try { document.execCommand("paste"); } catch (_) {}
    box.removeEventListener("paste", onPaste, true);
    box.blur(); // sonst bleibt Vimium im Insert-Mode
    box.remove();
    return result; // null = Lesen nicht erlaubt
  };

  // Bilder/Dateien wie Strg+V an das Feld schicken. true = Seite hat es übernommen.
  const pasteFiles = (el, files) => {
    const dt = new DataTransfer();
    for (const f of files) dt.items.add(f);
    const ev = new ClipboardEvent("paste", { clipboardData: dt, bubbles: true, cancelable: true });
    el.dispatchEvent(ev);
    return ev.defaultPrevented;
  };

  const insertText = (el, text) => {
    // insertText wie echtes Tippen → Strg+Z und input-Events (React & Co.) funktionieren
    if (document.execCommand("insertText", false, text)) return;
    try {
      el.setRangeText(text, el.selectionStart, el.selectionEnd, "end");
      el.dispatchEvent(new Event("input", { bubbles: true }));
    } catch (_) { HUD.show("Einfügen nicht möglich", 1500); }
  };

  NormalModeCommands.pasteIntoInput = function () {
    const clip = readClipboard();
    if (!clip) { HUD.show("Zwischenablage nicht lesbar (clipboardRead fehlt?)", 2000); return; }
    if (!clip.text && clip.files.length === 0) { HUD.show("Zwischenablage ist leer", 1500); return; }

    NormalModeCommands.focusInput(1); // exakt das Ziel von gi
    const el = document.activeElement;
    if (!el || !DomUtils.isEditable(el)) return; // focusInput meldet "no inputs" selbst

    if (clip.files.length > 0) {
      if (pasteFiles(el, clip.files)) return;
      if (!clip.text) { HUD.show("Dieses Feld nimmt keine Bilder an", 1500); return; }
    }
    insertText(el, clip.text);
  };
})();
