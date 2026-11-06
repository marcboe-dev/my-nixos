// Readline-/Vim-Kürzel in Textfeldern:
//   Ctrl+U         vom Cursor bis zum Anfang des Felds löschen
//   Alt+B          ein Wort zurück
//   Alt+F          ein Wort vor (an das Wortende, wie in bash)
//   Alt+D          vom Cursor bis zum Ende des nächsten Worts löschen
//   Alt+Backspace  vom Cursor bis zum Anfang des vorigen Worts löschen
//                  (Ctrl+W ist in Chromium reserviert und nicht abfangbar)
// Nach Esc (Vimium nimmt dem Feld den Fokus = "Normal Mode"):
//   I  zurück ins zuletzt benutzte Feld, Zeilenanfang (erstes Nicht-Leerzeichen)
//   A  zurück ins zuletzt benutzte Feld, Zeilenende
function deepActive(el = document.activeElement) {
  while (el && el.shadowRoot && el.shadowRoot.activeElement) el = el.shadowRoot.activeElement;
  return el;
}

const isWord = (c) => /[\p{L}\p{N}_]/u.test(c);

function wordForward(v, i) {
  while (i < v.length && !isWord(v[i])) i++;
  while (i < v.length && isWord(v[i])) i++;
  return i;
}

function wordBackward(v, i) {
  while (i > 0 && !isWord(v[i - 1])) i--;
  while (i > 0 && isWord(v[i - 1])) i--;
  return i;
}

function stop(e) {
  e.preventDefault();
  e.stopImmediatePropagation();
}

const isEditable = (el) =>
  !!el && (el.isContentEditable ||
    (typeof el.selectionStart === "number" && !el.readOnly && !el.disabled));

// Bereich [start, end) in <input>/<textarea> löschen (bleibt mit Ctrl+Z rückgängig machbar)
function deleteRange(el, start, end) {
  if (start >= end) return;
  el.setSelectionRange(start, end);
  document.execCommand("delete");
}

// ── Readline-Kürzel (Insert Mode) ───────────────────────────
document.addEventListener("keydown", (e) => {
  if (e.shiftKey || e.metaKey) return;
  const k = e.key.toLowerCase();
  let action = null;
  if (e.ctrlKey && !e.altKey && k === "u") action = "kill";
  else if (e.altKey && !e.ctrlKey && k === "b") action = "back";
  else if (e.altKey && !e.ctrlKey && k === "f") action = "forward";
  else if (e.altKey && !e.ctrlKey && k === "d") action = "killword";
  else if (e.altKey && !e.ctrlKey && k === "backspace") action = "killback";
  if (!action) return;

  const el = deepActive();
  if (!el) return;

  // contenteditable (z.B. Gmail, Notion, Chat-Felder)
  if (el.isContentEditable) {
    const sel = getSelection();
    if (!sel.rangeCount) return;
    stop(e);
    if (action === "kill") {
      if (sel.isCollapsed) {
        // Editier-Wurzel suchen, damit nur innerhalb des Felds gelöscht wird
        let host = el;
        while (host.parentElement && host.parentElement.isContentEditable) host = host.parentElement;
        const range = sel.getRangeAt(0).cloneRange();
        range.setStart(host, 0);
        sel.removeAllRanges();
        sel.addRange(range);
      }
      if (!sel.isCollapsed) document.execCommand("delete");
    } else if (action === "killword" || action === "killback") {
      if (sel.isCollapsed) sel.modify("extend", action === "killword" ? "forward" : "backward", "word");
      if (!sel.isCollapsed) document.execCommand("delete");
    } else {
      sel.modify("move", action === "back" ? "backward" : "forward", "word");
    }
    return;
  }

  // <input> / <textarea> (nur Typen mit Cursor; email/number liefern null)
  if (typeof el.selectionStart !== "number" || el.readOnly || el.disabled) return;
  stop(e);

  const { selectionStart: s, selectionEnd: en, value: v } = el;
  const collapsed = s === en; // bei Markierung: einfach die Markierung löschen

  if (action === "kill") return deleteRange(el, collapsed ? 0 : s, en);
  if (action === "killword") return deleteRange(el, s, collapsed ? wordForward(v, s) : en);
  if (action === "killback") return deleteRange(el, collapsed ? wordBackward(v, s) : s, en);

  const pos = action === "back" ? wordBackward(v, s) : wordForward(v, en);
  el.setSelectionRange(pos, pos);
}, true);

// ── Vim-artiges I / A nach Esc (Normal Mode) ────────────────
// Vimium nimmt bei Esc dem Feld den Fokus. Wir merken uns das Feld samt
// Cursor und springen bei I (wie Pos1) bzw. A (wie Ende) dorthin zurück;
// Vimium schaltet beim Fokussieren selbst wieder in den Insert Mode.
let parked = null; // { el, caret, range }
let mouseDown = false;

addEventListener("mousedown", () => { mouseDown = true; parked = null; }, true);
addEventListener("mouseup", () => { mouseDown = false; }, true);

// Fokusverlust ohne Klick und ohne neues Ziel (also kein Tab) = Esc von Vimium
document.addEventListener("focusout", (e) => {
  const el = e.composedPath()[0]; // funktioniert auch im Shadow DOM
  if (!isEditable(el) || e.relatedTarget || mouseDown) return;
  const sel = getSelection();
  const saved = {
    el,
    caret: el.isContentEditable ? null : el.selectionStart,
    range: el.isContentEditable && sel.rangeCount ? sel.getRangeAt(0).cloneRange() : null,
  };
  // Alt+Tab / Fensterwechsel zählt nicht als "Normal Mode"
  setTimeout(() => { parked = document.hasFocus() ? saved : null; }, 0);
}, true);

// Anderes Element bekommt Fokus → Feld vergessen
document.addEventListener("focusin", () => { parked = null; }, true);

// Macht dasselbe wie die Pos1- (I) bzw. Ende-Taste (A)
function homeEnd(el, key, caret, range) {
  if (el.isContentEditable) {
    const sel = getSelection();
    if (range) { sel.removeAllRanges(); sel.addRange(range.cloneRange()); }
    sel.modify("move", key === "I" ? "backward" : "forward", "lineboundary");
    return;
  }
  const v = el.value;
  let pos;
  if (el.tagName !== "TEXTAREA") {
    pos = key === "I" ? 0 : v.length; // einzeiliges Feld: Pos1 = Anfang, Ende = Ende
  } else if (key === "I") {
    pos = caret > 0 ? v.lastIndexOf("\n", caret - 1) + 1 : 0;
  } else {
    pos = v.indexOf("\n", caret);
    if (pos === -1) pos = v.length;
  }
  el.setSelectionRange(pos, pos);
}

document.addEventListener("keydown", (e) => {
  if (!parked || e.ctrlKey || e.altKey || e.metaKey) return;
  if (e.key !== "I" && e.key !== "A") return;
  if (isEditable(deepActive())) return; // schon im Insert Mode → normal tippen

  const { el, caret, range } = parked;
  parked = null;
  if (!el.isConnected) return;
  stop(e); // verhindert, dass "I"/"A" als Zeichen eingefügt wird
  const key = e.key;
  el.focus();
  homeEnd(el, key, caret, range);

  // Manche Seiten setzen den Cursor nach dem Fokussieren asynchron ans Ende.
  // Deshalb kurz danach noch zweimal setzen – aber nur, wenn das Feld noch
  // Fokus hat und du in der Zwischenzeit nichts getippt hast.
  let typed = false;
  el.addEventListener("input", () => { typed = true; }, { once: true });
  const again = () => { if (!typed && deepActive() === el) homeEnd(el, key, caret, range); };
  setTimeout(again, 0);
  setTimeout(again, 50);
}, true);
