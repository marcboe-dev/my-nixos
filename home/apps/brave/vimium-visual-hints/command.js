// Meldet den Befehl "visualHints" bei Vimium an (wird an all_commands.js angehängt).
// Die Umsetzung steht in picker.js, die Taste in default.nix (keyMappings).
allCommands.push({
  name: "visualHints",
  desc: "Visual-Mode per Wort-Hint starten (wie Surfingkeys v)",
  group: "navigation",
  noRepeat: true,
});
