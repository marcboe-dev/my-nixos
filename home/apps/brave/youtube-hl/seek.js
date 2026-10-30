window.addEventListener('keydown', e => {
  const t = e.target;
  if (t.isContentEditable || /INPUT|TEXTAREA|SELECT/.test(t.tagName)) return;
  // AltGr nicht blockieren (auf AT/DE-Layout für [ ] nötig)
  if (e.ctrlKey || e.metaKey || (e.altKey && !e.getModifierState('AltGraph'))) return;

  const p = document.getElementById('movie_player'); // YouTube-Player-API
  const v = document.querySelector('video');
  if (!v) return;

  const clamp = (x, lo, hi) => Math.min(hi, Math.max(lo, x));

  const seek = s => p?.seekTo
    ? p.seekTo(p.getCurrentTime() + s, true)
    : (v.currentTime += s);

  const vol = d => {
    if (p?.setVolume) {
      if (p.isMuted()) p.unMute();
      p.setVolume(clamp(p.getVolume() + d, 0, 100));
    } else {
      v.muted = false;
      v.volume = clamp(v.volume + d / 100, 0, 1);
    }
  };

  const speed = d => {
    if (p?.setPlaybackRate) {
      const rates = p.getAvailablePlaybackRates?.() ?? [0.25, 2];
      const r = d === 0 ? 1 : clamp(p.getPlaybackRate() + d, Math.min(...rates), Math.max(...rates));
      p.setPlaybackRate(r);
    } else {
      v.playbackRate = d === 0 ? 1 : clamp(v.playbackRate + d, 0.25, 4);
    }
  };

  const actions = {
    h: () => seek(-5),   l: () => seek(5),
    H: () => seek(-10),  L: () => seek(10),    // Shift+h/l
    j: () => vol(-5),    k: () => vol(5),
    '[': () => speed(-0.25),
    ']': () => speed(0.25),
    '=': () => speed(0),                       // zurück auf 1×
  };

  const a = actions[e.key];
  if (!a) return;
  a();
  e.preventDefault();
  e.stopImmediatePropagation();
}, true);
