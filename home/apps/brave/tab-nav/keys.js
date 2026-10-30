// Alt+h / Alt+l auf Webseiten abfangen und an background.js schicken
window.addEventListener("keydown", (e) => {
  if (!e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return;

  const command = e.code === "KeyH" ? "tab-left" : e.code === "KeyL" ? "tab-right" : null;
  if (!command) return;

  e.preventDefault();
  e.stopImmediatePropagation();
  chrome.runtime.sendMessage(command);
}, true);
