// ---- Eigener Vimium-Befehl "focusScrollable" (eingebaut über home/apps/brave/default.nix) ----
// Zeigt Hints auf allen scrollbaren Bereichen der Seite. Nach Auswahl scrollen
// j/k/h/l/d/u/gg/G genau diesen Bereich – wie nach einem Mausklick hinein.
// Läuft im selben Kontext wie Vimium und setzt dessen `activatedElement` (scroller.js).
(() => {
  const MIN_W = 40, MIN_H = 20;

  const canScroll = (el, cs) =>
    (/(auto|scroll|overlay)/.test(cs.overflowY) && el.scrollHeight > el.clientHeight + 1) ||
    (/(auto|scroll|overlay)/.test(cs.overflowX) && el.scrollWidth > el.clientWidth + 1);

  const visibleRect = (el) => {
    const r = el === document.scrollingElement
      ? { left: 0, top: 0, right: innerWidth, bottom: innerHeight }
      : el.getBoundingClientRect();
    const left = Math.max(r.left, 0), top = Math.max(r.top, 0);
    const right = Math.min(r.right, innerWidth), bottom = Math.min(r.bottom, innerHeight);
    if (right - left < MIN_W || bottom - top < MIN_H) return null;
    return { left, top, width: right - left, height: bottom - top };
  };

  function findScrollables() {
    const found = [];
    const root = document.scrollingElement;
    if (root && root.scrollHeight > innerHeight + 1 &&
        getComputedStyle(document.body || root).overflowY !== "hidden") {
      found.push({ el: root, rect: visibleRect(root), vertical: true });
    }
    for (const el of document.querySelectorAll("*")) {
      if (el === root) continue;
      // Billiger Vorfilter, bevor getComputedStyle bemüht wird
      if (el.scrollHeight <= el.clientHeight + 1 && el.scrollWidth <= el.clientWidth + 1) continue;
      const cs = getComputedStyle(el);
      if (cs.visibility === "hidden" || !canScroll(el, cs)) continue;
      const rect = visibleRect(el);
      if (!rect) continue;
      const vertical = /(auto|scroll|overlay)/.test(cs.overflowY) && el.scrollHeight > el.clientHeight + 1;
      found.push({ el, rect, vertical });
    }
    // Große, vertikal scrollbare Bereiche zuerst → bekommen die einfachsten Labels
    found.sort((a, b) => (b.vertical - a.vertical) || (b.rect.width * b.rect.height - a.rect.width * a.rect.height));
    return found;
  }

  function makeLabels(n) {
    const chars = (Settings.get("linkHintCharacters") || "sadfjklewcmpgh").toLowerCase().split("");
    if (n <= chars.length) return chars.slice(0, n);
    const labels = [];
    for (const a of chars) for (const b of chars) labels.push(a + b);
    return labels.slice(0, n);
  }

  function drawOverlay(targets) {
    const overlay = document.createElement("div");
    overlay.style.cssText = "position:fixed;inset:0;z-index:2147483647;pointer-events:none;";
    for (const t of targets) {
      const box = document.createElement("div");
      const { left, top, width, height } = t.rect;
      box.style.cssText = `position:fixed;left:${left}px;top:${top}px;width:${width}px;height:${height}px;` +
        "box-sizing:border-box;border:2px solid #e0af68;background:rgba(224,175,104,.08);border-radius:4px;";
      const label = document.createElement("div");
      label.textContent = t.label.toUpperCase();
      label.style.cssText = "position:absolute;left:4px;top:4px;padding:2px 6px;border-radius:3px;" +
        "font:bold 14px monospace;color:#1a1b26;background:#e0af68;box-shadow:0 1px 3px rgba(0,0,0,.4);";
      t.labelEl = label;
      box.appendChild(label);
      overlay.appendChild(box);
    }
    document.documentElement.appendChild(overlay);
    return overlay;
  }

  function flash(rect) {
    const f = document.createElement("div");
    f.style.cssText = `position:fixed;left:${rect.left}px;top:${rect.top}px;width:${rect.width}px;height:${rect.height}px;` +
      "z-index:2147483647;pointer-events:none;box-sizing:border-box;border:3px solid #9ece6a;border-radius:4px;" +
      "transition:opacity .4s;";
    document.documentElement.appendChild(f);
    setTimeout(() => (f.style.opacity = "0"), 250);
    setTimeout(() => f.remove(), 700);
  }

  function select(target) {
    // Fokus aus Textfeldern nehmen, sonst landen j/k dort statt beim Scrollen
    const active = document.activeElement;
    if (active && DomUtils.isEditable(active)) active.blur();
    activatedElement = target.el; // Vimiums Scroll-Ziel (siehe content_scripts/scroller.js)
    flash(target.rect);
  }

  NormalModeCommands.focusScrollable = function () {
    const targets = findScrollables();
    if (targets.length === 0) {
      HUD.show("Keine scrollbaren Bereiche gefunden", 1500);
      return;
    }
    if (targets.length === 1) return select(targets[0]);

    makeLabels(targets.length).forEach((l, i) => (targets[i].label = l));
    const overlay = drawOverlay(targets);
    let typed = "";

    const mode = new Mode();
    mode.init({
      name: "scroll-picker",
      indicator: "Bereich zum Scrollen wählen",
      exitOnEscape: true,
      suppressAllKeyboardEvents: true,
      keydown: (event) => {
        if (event.key === "Backspace") typed = typed.slice(0, -1);
        else {
          const ch = KeyboardUtils.getKeyChar(event);
          if (!ch || ch.length !== 1) return;
          typed += ch.toLowerCase();
        }
        const matches = targets.filter((t) => t.label.startsWith(typed));
        if (matches.length === 0) { mode.exit(); return; }
        if (matches.length === 1 && matches[0].label === typed) {
          mode.exit();
          select(matches[0]);
          return;
        }
        for (const t of targets) t.labelEl.parentElement.style.display = t.label.startsWith(typed) ? "" : "none";
      },
    });
    mode.onExit(() => overlay.remove());
  };
})();
