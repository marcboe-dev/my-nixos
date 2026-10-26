# Dotfiles-Repo aktualisieren: git fetch → git status → git pull
# und das Ergebnis als Notification anzeigen.
# Aufruf: Tastenkürzel Mod+Alt+G (niri + qtile) oder einfach `dotfiles-sync` im Terminal.

dir="${DOTFILES_DIR:-$HOME/nixos-dotfiles}"

notify() { notify-send -a "Dotfiles" "$@" || true; }

# Beim Tastenkürzel gibt es kein Terminal → nie auf Passwort-Eingabe warten
export GIT_TERMINAL_PROMPT=0

# Zweimal drücken startet keinen zweiten Lauf
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/dotfiles-sync.lock"
flock -n 9 || exit 0

if [ ! -d "$dir/.git" ]; then
  notify -u critical "Kein Repo" "$dir existiert nicht"
  exit 1
fi
cd "$dir"

branch="$(git rev-parse --abbrev-ref HEAD)"
if ! upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
  notify -u critical "Kein Upstream" "Branch '$branch' hat keinen Remote-Branch"
  exit 1
fi

# ── 1. fetch ─────────────────────────────────────────
if ! err="$(timeout 30 git fetch --prune 2>&1)"; then
  notify -u critical "Fetch fehlgeschlagen" "${err:-Kein Internet?}"
  exit 1
fi

# ── 2. status ────────────────────────────────────────
read -r ahead behind < <(git rev-list --left-right --count "HEAD...$upstream")
dirty="$(git status --porcelain | wc -l)"
git status -sb # nur sichtbar, wenn im Terminal gestartet

hints=""
[ "$ahead" -gt 0 ] && hints+=$'\n'"$ahead lokale Commits nicht gepusht"
[ "$dirty" -gt 0 ] && hints+=$'\n'"$dirty Dateien geändert, nicht committet"

if [ "$behind" -eq 0 ]; then
  notify "✓ Schon aktuell" "Branch $branch$hints"
  exit 0
fi

if [ "$ahead" -gt 0 ]; then
  notify -u critical "Verzweigt" "Lokal $ahead, remote $behind neue Commits."$'\n'"Bitte manuell: git pull"
  exit 1
fi

# ── 3. pull ──────────────────────────────────────────
old="$(git rev-parse HEAD)"
# --ff-only: nur vorspulen, nie mergen/rebasen → kann nichts kaputt machen
if ! err="$(git pull --ff-only 2>&1)"; then
  notify -u critical "Pull fehlgeschlagen" "${err: -300}"
  exit 1
fi

msg="$behind neue Commits geholt ($branch)"
# config/* sind Out-of-Store-Symlinks und wirken sofort.
# Geänderte .nix-Dateien oder flake.lock brauchen aber einen Rebuild.
changed="$(git diff --name-only "$old" HEAD)"
if grep -qE '\.nix$|^flake\.lock$' <<<"$changed"; then
  msg+=$'\n'"Nix-Dateien geändert → nrs ausführen"
fi

notify "✓ Dotfiles aktualisiert" "$msg$hints"
