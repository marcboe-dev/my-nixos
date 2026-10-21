# Google Drive auf neuer Maschine einrichten

Voraussetzung: Die Maschine läuft bereits mit der Config aus
[marcboe-dev/my-nixos](https://github.com/marcboe-dev/my-nixos), also Repo geklont und
`nrs` ausgeführt. Damit sind `rclone`, Obsidian und der Service `gdrive-mount`
schon installiert.

Was fehlt, ist nur der Login bei Google. Der Token ist ein Geheimnis und liegt
deshalb bewusst **nicht** im Repo.

---

## Benötigt

Aus Bitwarden:

- **Client-ID**
- **Clientschlüssel**

Beides stammt aus dem bestehenden Google-Cloud-Projekt `rclone`
(Google Auth Platform → Clients). Dort muss nichts neu angelegt werden, Projekt und Client
werden auf jeder Maschine wiederverwendet.

---

## 1. rclone einrichten

```bash
rclone config
```

| Frage | Antwort |
|---|---|
| New remote? | `n` |
| name> | `gdrive` (exakt so, der Service mountet `gdrive:`) |
| Storage> | `drive` |
| client_id> | Client-ID aus Bitwarden |
| client_secret> | Clientschlüssel aus Bitwarden |
| scope> | `1` (voller Zugriff) |
| service_account_file> | Enter |
| Edit advanced config? | `n` |
| Use web browser to authenticate? | `y` |

Im Browser (öffnet sich automatisch, sonst den Link aus dem Terminal öffnen):

1. Google-Konto wählen
2. Warnung „App nicht überprüft“ → **Erweitert** → **Zu rclone wechseln (unsicher)**
3. Zugriff erlauben (alle Kästchen anhaken) → „Success“

Im Terminal erscheint `Got code`. Danach:

| Frage | Antwort |
|---|---|
| Configure as Shared Drive? | `n` |
| Keep this remote? | `y` |
| (Menü) | `q` |

Ergebnis: `~/.config/rclone/rclone.conf` mit Client-ID, Schlüssel und Token.

---

## 2. Testen und Mount starten

```bash
rclone lsd gdrive:                     # Verbindung testen: zeigt Ordner im Drive
systemctl --user start gdrive-mount    # Drive nach ~/GoogleDrive einhängen
ls ~/GoogleDrive                       # sollte dieselben Ordner zeigen
```

Den Service von Hand zu starten ist nur dieses eine Mal nötig. Beim letzten Login gab es
noch keine `rclone.conf`, deshalb wurde er übersprungen. Ab dem nächsten Login
startet er automatisch.

---

## 3. Obsidian

Obsidian starten → **Open folder as vault** → Vault-Ordner in `~/GoogleDrive/…` wählen.

Einstellungen, Plugins und Themes liegen im `.obsidian/`-Ordner des Vaults und kommen
über die Cloud automatisch mit.

---

## Fehlerbehebung

| Problem | Lösung |
|---|---|
| `rclone lsd gdrive:` gibt Fehler | Client-ID oder Schlüssel falsch → `rclone config` → `e` (edit) → `gdrive` |
| `~/GoogleDrive` leer | `systemctl --user status gdrive-mount` prüfen |
| Login läuft nach 7 Tagen ab | App noch im Testmodus → Cloud Console → Audience → **Publish app**, danach `rclone config reconnect gdrive:` |
| Google-Login neu nötig (Token widerrufen o. ä.) | `rclone config reconnect gdrive:` |
