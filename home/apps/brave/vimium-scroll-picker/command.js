// Meldet den Befehl "focusScrollable" bei Vimium an (wird an all_commands.js angehängt).
// Die Umsetzung steht in picker.js, die Taste in default.nix (keyMappings).
list.push({
  name: "focusScrollable",
  desc: "Scrollbaren Bereich per Hint auswählen",
  group: "navigation",
  noRepeat: true,
});
