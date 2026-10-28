# Heimserver: Tailscale-Exit-Node & Fernzugriff

Ein alter Laptop daheim läuft headless mit NixOS (`profiles/server.nix`).
Er ist ein **Tailscale-Exit-Node**: Unterwegs geht der Traffic des
Firmenlaptops über den Heimanschluss, und FortiClient sieht eine
österreichische IP.

## Wo wird was ausgeführt?

| Zeichen | Ort | Eingabezeile | Wie man hinkommt |
|---|---|---|---|
| 🖥️ | **Server (per SSH)** | `marc@nixos-server` | in der VM: `ssh marc@nixos-server` |
| 💻 | **VM (normal)** | `marc@nixos-vm` | in der SSH-Sitzung: `exit` |
| 🪟 | **Windows** (Firmenlaptop) | PowerShell / Tray-Icon | – |
| 🌐 | **Browser** | – | – |

Direkt an Tastatur und Bildschirm des Server-Laptops arbeitet man nur bei
der Installation und im Notfall.

---

## 1. Server installieren

**Direkt am Server-Laptop** (frisches NixOS, UEFI):

```bash
nix run github:marcboe-dev/my-nixos -- server server     # neuer Server-Host
nix run github:marcboe-dev/my-nixos -- server            # Neuinstallation eines bestehenden
```

`install.sh` legt `hosts/server/` an, baut das System und startet die
Tailscale-Anmeldung (Link auf einem beliebigen Gerät öffnen und bestätigen).

Prüfen bzw. nachholen:

```bash
tailscale status                              # nixos-server mit 100.x.y.z?
sudo tailscale login                          # falls "Logged out"
sudo systemctl restart tailscaled-set.service # Exit-Node- & SSH-Flags anwenden
```

## 2. Tailscale-Admin-Konsole (einmalig)

🌐 https://login.tailscale.com/admin/machines → bei `nixos-server` auf `…`:

1. **Edit route settings** → **Use as exit node** anhaken
2. **Disable key expiry** (sonst fliegt der Server nach ~6 Monaten raus)

## 3. Firmenlaptop: Tailscale auf Windows

FortiClient läuft unter Windows, daher muss **Windows** den Exit Node nutzen,
nicht die VM.

🪟 **Windows**

1. Tailscale installieren: https://tailscale.com/download/windows
   (Adminrechte nötig, ggf. über die IT)
2. Im Tray-Icon mit **demselben Account** anmelden
3. Tray-Icon → **Exit node** → `nixos-server`
4. Im selben Menü **Allow local network access** aktivieren
   (Hotel-Portale, lokale Drucker)
5. https://ipinfo.io öffnen → Land **AT**, dein Provider
6. **Erst danach** FortiClient verbinden

Ausschalten: Tray-Icon → Exit node → **None**.

IPv4 und IPv6 prüfen (beide müssen der Server-IP entsprechen):

```powershell
curl.exe -4 ifconfig.me
curl.exe -6 ifconfig.me
```

🖥️ **Server (per SSH)**, zum Vergleich:

```bash
curl -4 ifconfig.me; echo
curl -6 ifconfig.me; echo
```

## 4. VM: Tailscale für den Zugriff aufs Tailnet

In `hosts/vm/default.nix` (die VM nutzt selbst keinen Exit Node):

```nix
services.tailscale.enable = true;
```

💻 **VM (normal)**

```bash
cd ~/nixos-dotfiles
nrs
sudo tailscale up
sudo tailscale set --operator=marc   # danach tailscale-Befehle ohne sudo
tailscale status
```

## 5. Mit dem Server verbinden

💻 **VM (normal)**

```bash
ssh marc@nixos-server        # interaktive Shell am Server
ssh marc@nixos-server 'cmd'  # einzelnen Befehl ausführen, danach zurück in der VM
```

Unter 🪟 Windows funktioniert derselbe `ssh`-Befehl in PowerShell.

- Beim **ersten Mal** fragt SSH, ob du dem Rechner vertraust. Antwort: `yes`
  (das ganze Wort, `y` reicht nicht).
- Fingerprint prüfen, 🖥️ direkt am Server:
  `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`
- Nach einer **Neuinstallation** des Servers warnt SSH
  („REMOTE HOST IDENTIFICATION HAS CHANGED“). Dann alten Eintrag löschen:
  `ssh-keygen -R nixos-server`
- Findet die VM den Namen `nixos-server` nicht: `ssh marc@100.x.y.z`
  (IP aus `tailscale status`).
- Für längere Sitzungen am Server `tmux` starten. Bei einem Abbruch holt
  `tmux attach` alles zurück.

## 6. GitHub-Zugang per SSH-Schlüssel

GitHub akzeptiert beim Push kein Kontopasswort. Stattdessen bekommt jeder
Rechner einen eigenen SSH-Schlüssel:

| Rechner | Art des Schlüssels | Wo bei GitHub eintragen |
|---|---|---|
| Server | **Deploy Key** (darf nur `my-nixos`) | Repo → Settings → Deploy keys |
| VM | Konto-Schlüssel (alle Repos) | Profil → Settings → SSH and GPG keys |

Die Schritte sind auf beiden Rechnern gleich, nur der Kommentar (`-C`)
und der Eintragungsort unterscheiden sich.

### 6.1 Schlüssel erzeugen

🖥️ **Server (per SSH)** bzw. 💻 **VM (normal)**

```bash
ls ~/.ssh                                          # gibt es schon id_ed25519(.pub)?
ssh-keygen -t ed25519 -C "marc@nixos-server"       # bzw. "marc@nixos-vm"
```

Alle drei Fragen mit Enter bestätigen (Standardpfad, keine Passphrase).

| Datei | Bedeutung | Weitergeben? |
|---|---|---|
| `~/.ssh/id_ed25519` | privater Schlüssel (wie ein Passwort) | **niemals** |
| `~/.ssh/id_ed25519.pub` | öffentlicher Schlüssel (wie ein Schloss) | ja, an GitHub |

### 6.2 Öffentlichen Schlüssel bei GitHub eintragen

```bash
cat ~/.ssh/id_ed25519.pub     # ganze Zeile "ssh-ed25519 AAAA… marc@…" kopieren
```

🌐 **Browser**

- **Server:** Repo `my-nixos` → **Settings → Deploy keys → Add deploy key**,
  Titel `nixos-server`, Zeile einfügen, **Allow write access** anhaken.
- **VM:** Profilbild → **Settings → SSH and GPG keys → New SSH key**,
  Titel `nixos-vm`, Zeile einfügen.

### 6.3 Verbindung testen

```bash
ssh -T git@github.com
```

Beim ersten Mal den Fingerprint prüfen und `yes` tippen. Für GitHub (ED25519):

```
SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU
```

Erwartete Antwort:
- Konto-Schlüssel: `Hi marcboe-dev! …`
- Deploy Key: `Hi marcboe-dev/my-nixos! …`

### 6.4 Repo von HTTPS auf SSH umstellen

```bash
cd ~/nixos-dotfiles
git remote -v                                       # zeigt noch https://…
git remote set-url origin git@github.com:marcboe-dev/my-nixos.git
git remote -v                                       # jetzt git@github.com:…
git push
```

`install.sh` funktioniert weiterhin, weil die Adresse `marcboe-dev/my-nixos`
enthält.

### 6.5 Optional: VM-Schlüssel als Notfallzugang zum Server

`profiles/server.nix` erlaubt jeden Schlüssel unter `keys/*.pub` für normales
SSH, auch im Heimnetz, falls Tailscale klemmt.

💻 **VM (normal)**

```bash
cd ~/nixos-dotfiles
mkdir -p keys
cp ~/.ssh/id_ed25519.pub keys/vm.pub
git add keys/vm.pub && git commit -m "SSH-Schlüssel der VM" && git push
```

Wirksam ab dem nächsten Server-Build (Abschnitt 7).

## 7. Alltag: Config ändern

**Regel:** Bearbeitet wird **in der VM**. Der Server bekommt nur fertige Builds
und holt sich Updates mit `git pull`.

💻 **VM (normal)**

```bash
cd ~/nixos-dotfiles
git pull
nvim profiles/server.nix                 # bzw. hosts/server/default.nix
git add -A                               # Flakes sehen nur Dateien, die Git kennt
nixos-rebuild switch --flake .#nixos-server \
  --target-host marc@nixos-server --sudo --ask-sudo-password
git commit -m "…" && git push
ssh marc@nixos-server 'cd ~/nixos-dotfiles && git pull'   # Server-Klon nachziehen
```

Die VM baut das System, kopiert es per SSH auf den Server und schaltet dort um.
Das `sudo`-Passwort ist das von `marc` **am Server**.

### Commit vom Server in die VM holen (ohne GitHub)

Falls doch einmal am Server committet wurde:

💻 **VM (normal)**

```bash
cd ~/nixos-dotfiles
git pull
git pull marc@nixos-server:nixos-dotfiles main
git push
```

### Rückgängig machen

🖥️ **Server (per SSH)**

```bash
sudo nixos-rebuild switch --rollback   # vorherige Generation
```

Alternativ beim Booten im Menü eine ältere Generation wählen.

## 8. Konsole am Server (Tastatur & Schrift)

Nur relevant, wenn man direkt am Server-Laptop sitzt.

**Sofort, bis zum Neustart** (direkt am Server):

```bash
sudo setfont -d                                     # Standardschrift verdoppeln
T=$(nix build nixpkgs#terminus_font --print-out-paths --no-link)
sudo setfont $T/share/consolefonts/ter-v32n.psf.gz  # Terminus testen (24/28/32)
```

Auf dem US-Layout: `y`/`z` vertauscht, `-` auf `ß`, `/` auf `-`,
`|` auf Shift + `#`.

**Dauerhaft:**

`profiles/base.nix`, Abschnitt Tastatur (gilt für alle Rechner):

```nix
console.keyMap = "de-latin1-nodeadkeys";
```

`hosts/server/default.nix` (Kopfzeile auf `{pkgs, ...}:` ändern):

```nix
console = {
  packages = [pkgs.terminus_font];
  font = "ter-v32n";
  earlySetup = true;
};
```

Dann wie in Abschnitt 7 bauen.

## 9. Test: „Ausland“ mit NordVPN-Hotspot simulieren

Ein Linux-Laptop (t14/t490) spannt einen Hotspot auf, dessen Traffic über
NordVPN aus Italien kommt. Er braucht dafür eine zweite Internetverbindung
(LAN-Kabel oder USB-Tethering vom Handy).

### Hotspot-Laptop

```bash
nordvpn connect Italy
curl ifconfig.me; echo                         # italienische IP?
nmcli device                                   # WLAN-Gerät, z.B. wlp3s0
nmcli device wifi hotspot ifname wlp3s0 ssid nix-test password 'testtest123'
sudo nixos-firewall-tool open udp 67           # DHCP für Hotspot-Clients
sudo nixos-firewall-tool open udp 53           # DNS
```

### Firmenlaptop (🪟), mit WLAN `nix-test` verbunden

| Schritt | Exit Node | Erwartung |
|---|---|---|
| a | aus | ipinfo.io zeigt **Italien** |
| b | aus | FortiClient wird **blockiert** (Geo-Sperre greift) |
| c | an | ipinfo.io zeigt **Österreich** |
| d | an | FortiClient **verbindet** |
| e | an | 1 h normal arbeiten (Teams, Dateien, Remote) |

Schritt b ist der Gegentest. Nur wenn er blockiert, beweist d etwas.

**Zeigt Schritt a keine italienische IP:** Die NordVPN-Firewall blockiert
weitergeleiteten Traffic.

```bash
nordvpn set firewall off                       # Achtung: Killswitch ist damit auch aus
nordvpn disconnect && nordvpn connect Italy
```

**Aufräumen:**

```bash
nmcli connection down Hotspot
sudo nixos-firewall-tool reset
nordvpn set firewall on
nordvpn disconnect
```

## 10. Fehlerbehebung

| Problem | Ursache / Lösung |
|---|---|
| `Host key verification failed` | Bei der Frage nicht `yes` getippt → erneut verbinden, `yes` |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | Server neu installiert → `ssh-keygen -R nixos-server` |
| `git push` fragt nach Benutzer/Passwort | Remote ist noch HTTPS → Abschnitt 6.4 |
| `nixos-server` nicht gefunden | Tailscale-IP statt Name verwenden (`tailscale status`) |
| Server nach Monaten nicht erreichbar | Key expiry nicht deaktiviert → Abschnitt 2 |
| FortiClient steht, Seiten/Dateien hängen | MTU-Problem durch verschachtelte Tunnel → MTU am FortiClient-Interface senken (z.B. 1280) |
| Flake findet neue Datei nicht | Datei ist Git unbekannt → `git add <datei>` |
| Hotspot-Client bekommt keine IP | Ports 67/53 nicht offen → Abschnitt 9 |
