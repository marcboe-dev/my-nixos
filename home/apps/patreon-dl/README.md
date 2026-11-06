# patreon-dl – Patreon-Kurs offline speichern

Lädt eine Patreon-Collection (Kurs) oder einzelne Posts komplett herunter:
Text, Anhänge, Bilder, Audio und Videos. Ergebnis ist ein Ordner mit einer
`index.html`, durch die man offline klicken kann.

Voraussetzung: `./patreon-dl` ist in `home/apps/default.nix` importiert und die Config
mit `nrs` gebaut, dann ist der Befehl `patreon-dl` da.
Login läuft über die Cookies aus Brave, also vorher einmal in Brave bei Patreon einloggen.

---

## 1. Erst auflisten (lädt nichts)

```bash
patreon-dl --list "https://www.patreon.com/collection/1570882?view=expanded"
```

Zeigt den Login-Namen und alle Posts in Kursreihenfolge. Wenn das klappt,
funktionieren Login und Collection.

## 2. Testlauf: nur die ersten 3 Posts

```bash
patreon-dl --test "https://www.patreon.com/collection/1570882?view=expanded"
```

Dann prüfen:

```bash
xdg-open ~/Patreon/<Kursname>/index.html
```

- Text vollständig, Bilder sichtbar?
- Anhänge in `anhaenge/` da und öffnen sie sich?
- Videos in `video/` da und abspielbar?
- Gibt es eine `failures.txt`?

Statt 3 geht auch jede andere Zahl: `--limit 5`.

## 3. Ganzer Kurs

```bash
patreon-dl "https://www.patreon.com/collection/1570882?view=expanded"
```

Bereits geladene Dateien vom Testlauf werden übersprungen. Bei Abbruch oder
Fehlern einfach denselben Befehl nochmal starten.

---

## Ergebnis

```
~/Patreon/<Kursname>/
├── index.html              Übersicht aller Lektionen
├── failures.txt            nur wenn etwas fehlgeschlagen ist
├── 001 - <Titel>/
│   ├── index.html          Lektion mit lokalen Links
│   ├── post.json           Rohdaten (für Fehlersuche)
│   ├── anhaenge/
│   ├── bilder/
│   └── video/
└── 002 - <Titel>/ …
```

## Optionen

| Option | Wirkung |
|---|---|
| `--list` | nur Posts auflisten, nichts laden |
| `--test` | nur die ersten 3 Posts |
| `--limit N` | nur die ersten N Posts |
| `--no-video` | Videos überspringen (schnell, für Tests) |
| `-o DIR` | anderer Zielordner (Standard `~/Patreon`) |
| `--delay S` | Pause zwischen Posts in Sekunden (Standard 1.5) |
| `--cookies FILE` | `cookies.txt` statt Brave-Cookies |
| `--order oldest\|newest` | Reihenfolge ohne Abfrage festlegen |
| `--redo` | auch fertige Posts nochmal prüfen |

## Wenn der Login nicht klappt

Meldung *„Nicht eingeloggt“* oder Fehler beim Lesen der Brave-Cookies:

1. Brave komplett schließen und nochmal versuchen.
2. Sonst Cookies exportieren: in Brave die Extension „Get cookies.txt LOCALLY“,
   auf patreon.com exportieren, dann

```bash
   patreon-dl --cookies ~/Downloads/cookies.txt --test "<url>"
```

   Die `cookies.txt` danach löschen, sie ist ein Login.

## Hinweise

- URL immer in Anführungszeichen, wegen dem `?` in der URL.
- Externe Links im Text (Google Drive, Dropbox …) werden nicht mitgeladen.
- Nur für eigene, private Offline-Nutzung – nicht weitergeben.

## Entfernen

1. Ordner `home/apps/patreon-dl/` löschen
2. Zeile `./patreon-dl` in `home/apps/default.nix` löschen
3. `nrs`

Die heruntergeladenen Kurse in `~/Patreon` bleiben dabei erhalten.
