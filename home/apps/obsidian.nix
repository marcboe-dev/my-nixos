{
  lib,
  pkgs,
  ...
}: {
  home.packages = [pkgs.obsidian];

  # Obsidian: setzt bei jedem Rebuild/Boot "frame":"native" in obsidian.json,
  # damit Obsidian unter qtile keinen eigenen Fensterrahmen/Buttons zeichnet.
  # Nur dieser eine Wert wird geändert, die Vault-Liste bleibt erhalten.
  home.activation.obsidianFrame = lib.hm.dag.entryAfter ["writeBoundary"] ''
    f="$HOME/.config/obsidian/obsidian.json"
    mkdir -p "$(dirname "$f")"
    [ -s "$f" ] || echo '{}' > "$f"
    ${pkgs.jq}/bin/jq '.frame = "native"' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  '';
}
