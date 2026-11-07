// YouTube: Shift+j / Shift+k = Wiedergabegeschwindigkeit -/+ 0.05
// Vimium hat J/K per unmap freigegeben, siehe ../default.nix
const STEP = 0.05;
const MIN_RATE = 0.1;
const MAX_RATE = 16;

const isEditable = (el) =>
  el && (el.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(el.tagName));

// Kurze Einblendung des aktuellen Tempos (YouTube zeigt krumme Werte nicht an)
let toast, toastTimer;
const showRate = (rate) => {
  if (!toast) {
    toast = document.createElement("div");
    toast.style.cssText =
      "position:fixed;top:20px;left:50%;transform:translateX(-50%);z-index:2147483647;" +
      "background:rgba(0,0,0,.8);color:#fff;font:bold 18px sans-serif;" +
      "padding:8px 16px;border-radius:6px;pointer-events:none";
  }
  toast.textContent = `${rate.toFixed(2)}×`;
  document.documentElement.appendChild(toast);
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.remove(), 800);
};

window.addEventListener("keydown", (e) => {
  if (!e.shiftKey || e.altKey || e.ctrlKey || e.metaKey) return;
  const step = e.code === "KeyK" ? STEP : e.code === "KeyJ" ? -STEP : 0;
  if (!step || isEditable(document.activeElement)) return;

  const video = document.querySelector("video");
  if (!video) return;

  // vor YouTubes eigenem j/k-Handler (10s zurück / Pause) abfangen
  e.preventDefault();
  e.stopImmediatePropagation();

  const rate = Math.min(MAX_RATE, Math.max(MIN_RATE, Math.round((video.playbackRate + step) * 100) / 100));
  video.playbackRate = rate;
  showRate(rate);
}, true);
