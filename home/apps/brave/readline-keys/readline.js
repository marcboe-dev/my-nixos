// Readline-Kürzel in Textfeldern:
//   Ctrl+U  vom Cursor bis zum Anfang des Felds löschen
//   Alt+B   ein Wort zurück
//   Alt+F   ein Wort vor (an das Wortende, wie in bash)
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

document.addEventListener("keydown", (e) => {
  if (e.shiftKey || e.metaKey) return;
  const k = e.key.toLowerCase();
  let action = null;
  if (e.ctrlKey && !e.altKey && k === "u") action = "kill";
  else if (e.altKey && !e.ctrlKey && k === "b") action = "back";
  else if (e.altKey && !e.ctrlKey && k === "f") action = "forward";
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
    } else {
      sel.modify("move", action === "back" ? "backward" : "forward", "word");
    }
    return;
  }

  // <input> / <textarea> (nur Typen mit Cursor; email/number liefern null)
  if (typeof el.selectionStart !== "number" || el.readOnly || el.disabled) return;
  stop(e);

  if (action === "kill") {
    const end = el.selectionEnd;
    const start = el.selectionStart === end ? 0 : el.selectionStart;
    if (start >= end) return;
    el.setSelectionRange(start, end);
    document.execCommand("delete"); // bleibt mit Ctrl+Z rückgängig machbar
    return;
  }

  const pos = action === "back"
    ? wordBackward(el.value, el.selectionStart)
    : wordForward(el.value, el.selectionEnd);
  el.setSelectionRange(pos, pos);
}, true);
