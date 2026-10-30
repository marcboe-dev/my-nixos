// Wechselt zum linken/rechten Tab (mit Wrap-around).
// fromTab = Tab, aus dem der Tastendruck kam (zuverlässig unter Wayland)
async function switchTab(command, fromTab) {
  const step = command === "tab-left" ? -1 : command === "tab-right" ? 1 : 0;
  if (step === 0) return;

  let windowId, index;
  if (fromTab) {
    windowId = fromTab.windowId;
    index = fromTab.index;
  } else {
    // Fallback für Browser-Shortcuts: aktiven Tab im zuletzt fokussierten Fenster suchen
    const [active] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
    if (!active) return;
    windowId = active.windowId;
    index = active.index;
  }

  const tabs = await chrome.tabs.query({ windowId });
  if (tabs.length === 0) return;
  const next = tabs[(index + step + tabs.length) % tabs.length];
  chrome.tabs.update(next.id, { active: true });
}

// Weg 1: Browser-Shortcuts (falls in brave://extensions/shortcuts gesetzt)
chrome.commands.onCommand.addListener((command) => switchTab(command));

// Weg 2: Tastendruck aus dem Content-Script, sender.tab sagt woher er kam
chrome.runtime.onMessage.addListener((msg, sender) => { switchTab(msg, sender.tab); });
