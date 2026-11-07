// Meldet den Befehl "searchSelection" bei Vimium an (wird an all_commands.js angehängt).
// Die Umsetzung steht in search.js, die Taste in default.nix (keyMappings).
allCommands.push({
  name: "searchSelection",
  desc: "Markierten/kopierten Text suchen (wie Surfingkeys s)",
  group: "navigation",
  noRepeat: true,
});
