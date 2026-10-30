window.addEventListener('keydown', e => {
  const t = e.target;
  if (t.isContentEditable || /INPUT|TEXTAREA/.test(t.tagName)) return;
  if (e.ctrlKey || e.altKey || e.metaKey) return;
  const v = document.querySelector('video');
  if (!v) return;
  if (e.key === 'h') { v.currentTime -= 5; e.preventDefault(); e.stopImmediatePropagation(); }
  if (e.key === 'l') { v.currentTime += 5; e.preventDefault(); e.stopImmediatePropagation(); }
}, true);
