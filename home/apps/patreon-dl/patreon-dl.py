#!/usr/bin/env python3
"""patreon-dl – lädt einen Patreon-Kurs (Collection) oder einzelne Posts
komplett für die Offline-Nutzung herunter.

Pro Post:  Text (HTML), alle Anhänge, Bilder, Audio, Videos (via yt-dlp)
Gesamt:    index.html zum Durchklicken, failures.txt bei Fehlern

Aufruf:
  patreon-dl https://www.patreon.com/collection/123456
  patreon-dl https://www.patreon.com/posts/titel-987654
  patreon-dl urls.txt                       # eine Post-/Collection-URL pro Zeile
  patreon-dl --test <url>                   # Testlauf: nur die ersten 3 Posts
  patreon-dl --list <url>                   # nur auflisten, nichts laden

Login (eins davon):
  --browser brave        Cookies direkt aus Brave lesen (Standard; Brave vorher schließen)
  --cookies cookies.txt  Netscape-Cookie-Datei (z.B. Extension "Get cookies.txt LOCALLY")
  PATREON_SESSION=...    Wert des Cookies "session_id"

Nur für Inhalte, auf die du selbst Zugriff hast – privat, nicht weiterverbreiten.
"""

import argparse
import html
import http.cookiejar
import json
import os
import re
import sys
import time
from pathlib import Path
from urllib.parse import quote, unquote, urlparse

import requests

API = "https://www.patreon.com/api"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/130.0 Safari/537.36")

# Patreon hat die Relationen über die Jahre umbenannt -> von voll nach minimal probieren
INCLUDE_VARIANTS = [
    "attachments,attachments_media,images,audio,media",
    "attachments_media,images,audio,media",
    "images,media",
    "",
]


# ─── Hilfsfunktionen ───────────────────────────────────────────────

def log(msg):
    print(msg, flush=True)


def safe(name, maxlen=120):
    name = re.sub(r'[\x00-\x1f/\\:*?"<>|]', "_", str(name)).strip(" .")
    return (name or "unbenannt")[:maxlen]


def unique(path: Path, taken: set) -> Path:
    """Gleiche Dateinamen innerhalb eines Posts durchnummerieren."""
    stem, suf, n = path.stem, path.suffix, 2
    while str(path) in taken:
        path = path.with_name(f"{stem} ({n}){suf}")
        n += 1
    taken.add(str(path))
    return path


def name_from_url(url, fallback):
    base = unquote(Path(urlparse(url).path).name)
    return base if "." in base else fallback


# ─── HTTP ──────────────────────────────────────────────────────────

def make_session(args):
    s = requests.Session()
    s.headers.update({"User-Agent": UA, "Referer": "https://www.patreon.com/"})

    sid = args.session_id or os.environ.get("PATREON_SESSION")
    if args.cookies:
        jar = http.cookiejar.MozillaCookieJar(args.cookies)
        jar.load(ignore_discard=True, ignore_expires=True)
        for c in jar:
            s.cookies.set_cookie(c)
    elif sid:
        s.cookies.set("session_id", sid, domain=".patreon.com", path="/")
    else:
        for c in browser_cookies(args):
            s.cookies.set_cookie(c)
    return s


class _Quiet:
    """Logger für yt-dlp: schluckt Meldungen beim Durchprobieren der Keyrings."""
    def debug(self, *a, **k): pass
    info = warning = error = debug
    def progress_bar(self): return None


def browser_cookies(args):
    """Patreon-Cookies aus dem Browser lesen.

    yt-dlp erkennt unter niri den Keyring nicht und nimmt BASICTEXT. Brave
    verschlüsselt aber mit gnome-keyring (programs.niri aktiviert ihn).
    Deshalb: erst automatisch, dann die Keyrings der Reihe nach probieren,
    bis das Login-Cookie session_id dabei ist."""
    from yt_dlp.cookies import extract_cookies_from_browser
    keyrings = [args.keyring.upper()] if args.keyring else \
        [None, "GNOMEKEYRING", "KWALLET6", "KWALLET5", "BASICTEXT"]
    for kr in keyrings:
        try:
            jar = extract_cookies_from_browser(args.browser, args.profile,
                                               _Quiet(), keyring=kr)
        except Exception:
            continue
        cookies = [c for c in jar if c.domain.endswith("patreon.com")]
        if any(c.name == "session_id" for c in cookies):
            log(f"Cookies aus {args.browser} gelesen (Keyring: {kr or 'automatisch'})")
            return cookies
    log(f"Kein Login-Cookie in {args.browser} gefunden.")
    return []


def write_cookiefile(session, path: Path):
    """Cookies als Netscape-Datei für yt-dlp ablegen."""
    jar = http.cookiejar.MozillaCookieJar(str(path))
    for c in session.cookies:
        jar.set_cookie(c)
    jar.save(ignore_discard=True, ignore_expires=True)
    path.chmod(0o600)


def get(session, url, *, params=None, stream=False):
    for attempt in range(7):
        try:
            r = session.get(url, params=params, stream=stream, timeout=120)
        except requests.RequestException as e:
            wait = 5 * 2 ** attempt
            log(f"  Netzwerkfehler ({e.__class__.__name__}), warte {wait}s …")
            time.sleep(wait)
            continue
        if r.status_code == 429 or r.status_code >= 500:
            wait = int(r.headers.get("Retry-After") or 0) or 5 * 2 ** attempt
            log(f"  HTTP {r.status_code}, warte {wait}s …")
            time.sleep(wait)
            continue
        return r
    r.raise_for_status()
    return r


def api(session, path, params=None):
    r = get(session, API + path, params=params)
    r.raise_for_status()
    return r.json()


def download(session, url, dest: Path):
    """Lädt url nach dest. Ohne Endung wird der Name aus dem Server-Header genommen.
    Gibt den endgültigen Pfad zurück."""
    if dest.exists() and dest.stat().st_size > 0:
        return dest
    dest.parent.mkdir(parents=True, exist_ok=True)
    part = dest.with_name(dest.name + ".part")
    with get(session, url, stream=True) as r:
        r.raise_for_status()
        if not dest.suffix:
            m = re.search(r"filename\*?=(?:UTF-8'')?\"?([^\";]+)",
                          r.headers.get("Content-Disposition", ""))
            if m:
                dest = dest.with_name(safe(unquote(m.group(1))))
                if dest.exists() and dest.stat().st_size > 0:
                    return dest
        with open(part, "wb") as f:
            for chunk in r.iter_content(1 << 20):
                f.write(chunk)
    part.rename(dest)
    return dest


# ─── Patreon-API ───────────────────────────────────────────────────

def check_login(session):
    r = get(session, API + "/current_user")
    if r.status_code == 200:
        name = r.json()["data"]["attributes"].get("full_name", "?")
        log(f"Eingeloggt als: {name}")
        return

    # ── Diagnose: warum klappt der Login nicht? ──
    names = {c.name for c in session.cookies}
    server = r.headers.get("server", "?")
    log("Nicht eingeloggt. Diagnose:")
    log(f"  Patreon-Cookies gefunden: {len(names)}")
    log(f"  session_id vorhanden:     {'ja' if 'session_id' in names else 'NEIN'}")
    log(f"  Antwort:                  HTTP {r.status_code} (Server: {server})")
    log(f"  Inhalt:                   {r.text[:200]!r}")
    if "session_id" not in names:
        log("→ Brave-Cookies konnten nicht gelesen werden. Weg: --cookies cookies.txt")
    elif r.status_code == 403 and "cloudflare" in server.lower():
        log("→ Cloudflare blockt das Skript (Bot-Schutz), nicht dein Login.")
    else:
        log("→ Cookie da, aber abgelehnt: in Brave einmal aus- und wieder einloggen.")
    sys.exit(1)


def fetch_post(session, post_id):
    last = None
    for inc in INCLUDE_VARIANTS:
        params = {"json-api-version": "1.0"}
        if inc:
            params["include"] = inc
        r = get(session, f"{API}/posts/{post_id}", params=params)
        if r.status_code == 400:   # unbekannte Relation -> kleiner probieren
            last = r
            continue
        r.raise_for_status()
        return r.json()
    last.raise_for_status()


def collection_post_ids(session, coll_id):
    doc = api(session, f"/collection/{coll_id}",
              {"include": "posts", "json-api-version": "1.0"})
    attrs = doc["data"]["attributes"]
    ids = attrs.get("post_ids") or [
        p["id"] for p in doc["data"]["relationships"]["posts"]["data"]]
    return attrs.get("title") or f"Collection {coll_id}", [str(i) for i in ids]


def parse_target(url):
    m = re.search(r"/collection/(\d+)", url)
    if m:
        return "collection", m.group(1)
    m = re.search(r"/posts/(?:[^/?#]*-)?(\d+)", url)
    if m:
        return "post", m.group(1)
    sys.exit(f"Unbekannte URL: {url}\n"
             "Erwartet: …/collection/<id> oder …/posts/<titel>-<id>")


# ─── Video via yt-dlp ──────────────────────────────────────────────

def ytdlp(url, folder: Path, cookiefile, referer=None):
    import yt_dlp
    opts = {
        "outtmpl": str(folder / "video" / "%(title).120B [%(id)s].%(ext)s"),
        "cookiefile": str(cookiefile),
        "format": "bv*+ba/b",
        "merge_output_format": "mp4",
        "retries": 10,
        "fragment_retries": 10,
        "concurrent_fragment_downloads": 4,
        "quiet": True,
        "no_warnings": True,
    }
    if referer:
        opts["http_headers"] = {"Referer": referer}
    with yt_dlp.YoutubeDL(opts) as y:
        return y.download([url]) == 0


# ─── Ein Post ──────────────────────────────────────────────────────

def process_post(session, post_id, outdir: Path, idx, args, cookiefile):
    doc = fetch_post(session, post_id)
    a = doc["data"]["attributes"]
    title = a.get("title") or f"Post {post_id}"
    folder = outdir / f"{idx:03d} - {safe(title)}"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "post.json").write_text(json.dumps(doc, indent=2, ensure_ascii=False))
    log(f"\n[{idx:03d}] {title}")

    errors, attachments, taken = [], [], set()

    def grab(url, dest, label):
        """Gibt den gespeicherten Pfad (relativ zum Post-Ordner) zurück oder None."""
        try:
            final = download(session, url, dest)
            log(f"  ✓ {final.name}")
            return final.relative_to(folder)
        except Exception as e:
            errors.append(f"{label}: {e}")
            log(f"  ✗ {label}: {e}")
            return None

    if a.get("current_user_can_view") is False:
        log("  ! Kein Zugriff auf diesen Post (Tier zu niedrig?) – nur Teaser")
        errors.append("kein Zugriff")

    # 1) Anhänge, Bilder, Audio aus "included"
    #    (Patreon liefert dieselbe Datei oft doppelt: alt "attachment" + neu "media")
    seen_names = set()
    for item in doc.get("included", []):
        at = item.get("attributes") or {}
        if item["type"] == "attachment":
            url, name = at.get("url"), at.get("name")
        elif item["type"] == "media":
            url = at.get("download_url") or (at.get("image_urls") or {}).get("original")
            name = at.get("file_name")
        else:
            continue
        if not url:
            continue
        name = safe(name or name_from_url(url, f"datei_{item['id']}"))
        if name in seen_names:
            continue
        seen_names.add(name)
        rel = grab(url, unique(folder / "anhaenge" / name, taken), name)
        if rel:
            attachments.append(rel)

    # 2) Post-Datei (z.B. Audio/PDF direkt am Post); Videos -> yt-dlp
    pf = a.get("post_file") or {}
    is_video = a.get("post_type", "").startswith("video") or ".m3u8" in (pf.get("url") or "")
    if pf.get("url") and not is_video:
        name = safe(pf.get("name") or name_from_url(pf["url"], "post_datei"))
        rel = grab(pf["url"], unique(folder / "anhaenge" / name, taken), name)
        if rel:
            attachments.append(rel)

    # 3) Videos: erst den Post selbst (Patreon-Video, HLS), dann ein Embed (Vimeo/YouTube)
    embed = (a.get("embed") or {}).get("url")
    if not args.no_video and (is_video or embed):
        ok = False
        try:
            ok = ytdlp(a.get("url") or f"https://www.patreon.com/posts/{post_id}",
                       folder, cookiefile)
        except Exception as e:
            log(f"  ~ yt-dlp über Post-URL fehlgeschlagen: {e}")
        if not ok and embed:
            try:
                ok = ytdlp(embed, folder, cookiefile, referer="https://www.patreon.com/")
            except Exception as e:
                log(f"  ~ yt-dlp über Embed fehlgeschlagen: {e}")
        log("  ✓ Video" if ok else "  ✗ Video")
        if not ok:
            errors.append(f"Video: {embed or a.get('url')}")

    # 4) Bilder und Patreon-Dateilinks im Text herunterladen und Links umschreiben
    content = a.get("content") or a.get("teaser_text") or ""
    counter = iter(range(1, 10_000))

    def repl_img(m):
        url = html.unescape(m.group(2))
        ext = Path(urlparse(url).path).suffix or ".jpg"
        dest = unique(folder / "bilder" / f"bild_{next(counter):03d}{ext}", taken)
        rel = grab(url, dest, dest.name)
        return f'{m.group(1)}"{quote(rel.as_posix())}"' if rel else m.group(0)

    def repl_link(m):
        url = html.unescape(m.group(2))
        if not re.search(r"patreon\.com/file|patreonusercontent\.com", url):
            return m.group(0)
        name = safe(name_from_url(url, f"link_{next(counter):03d}"))
        rel = grab(url, unique(folder / "anhaenge" / name, taken), name)
        if rel:
            attachments.append(rel)
            return f'{m.group(1)}"{quote(rel.as_posix())}"'
        return m.group(0)

    content = re.sub(r'(<img[^>]*?\ssrc=)"([^"]+)"', repl_img, content)
    content = re.sub(r'(<a[^>]*?\shref=)"([^"]+)"', repl_link, content)

    videos = sorted(p.relative_to(folder) for p in (folder / "video").glob("*")
                    if p.suffix not in (".part", ".ytdl")) if (folder / "video").exists() else []
    write_post_html(folder, title, a, content, attachments, videos)
    return folder, title, errors


# ─── HTML-Ausgabe ──────────────────────────────────────────────────

CSS = """
:root{--bg:#fff;--fg:#1a1a1a;--mute:#666;--line:#ddd;--link:#0b57d0}
@media (prefers-color-scheme:dark){:root{--bg:#16161e;--fg:#c0caf5;--mute:#888;--line:#333;--link:#7aa2f7}}
body{background:var(--bg);color:var(--fg);font:16px/1.6 system-ui,sans-serif;max-width:860px;margin:2rem auto;padding:0 1rem}
a{color:var(--link)} img,video{max-width:100%;height:auto} small{color:var(--mute)}
li{margin:.3rem 0} hr{border:0;border-top:1px solid var(--line)}
"""


def page(title, body):
    return (f"<!doctype html><html lang='de'><meta charset='utf-8'>"
            f"<meta name='viewport' content='width=device-width,initial-scale=1'>"
            f"<title>{html.escape(title)}</title><style>{CSS}</style><body>{body}</body></html>")


def write_post_html(folder, title, a, content, attachments, videos):
    parts = [f"<p><a href='../index.html'>← Übersicht</a></p>",
             f"<h1>{html.escape(title)}</h1>",
             f"<small>{html.escape(a.get('published_at') or '')} · "
             f"<a href='{html.escape(a.get('url') or '')}'>Original</a></small><hr>"]
    for v in videos:
        if v.suffix.lower() in (".mp4", ".webm", ".m4a", ".mp3"):
            tag = "audio" if v.suffix.lower() in (".m4a", ".mp3") else "video"
            parts.append(f"<{tag} controls src='{quote(v.as_posix())}'></{tag}>")
        parts.append(f"<p><a href='{quote(v.as_posix())}'>{html.escape(v.name)}</a></p>")
    parts.append(content)
    if attachments:
        parts.append("<hr><h2>Anhänge</h2><ul>" + "".join(
            f"<li><a href='{quote(p.as_posix())}'>{html.escape(p.name)}</a></li>"
            for p in dict.fromkeys(attachments)) + "</ul>")
    (folder / "index.html").write_text(page(title, "".join(parts)), encoding="utf-8")


def write_index(outdir, title, entries):
    items = "".join(
        f"<li><a href='{quote(f.name)}/index.html'>{html.escape(t)}</a>"
        + (" <small>⚠ unvollständig</small>" if err else "") + "</li>"
        for f, t, err in entries)
    (outdir / "index.html").write_text(
        page(title, f"<h1>{html.escape(title)}</h1><ol>{items}</ol>"), encoding="utf-8")


# ─── main ──────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("target", help="Collection-/Post-URL oder Textdatei mit URLs")
    ap.add_argument("-o", "--out", default=str(Path.home() / "Patreon"),
                    help="Zielordner (Standard: ~/Patreon)")
    ap.add_argument("--browser", default="brave", help="Browser für Cookies (Standard: brave)")
    ap.add_argument("--profile", default=None, help="Browser-Profil (optional)")
    ap.add_argument("--keyring", default=None,
                help="Keyring erzwingen: gnomekeyring, kwallet6, basictext (Standard: probieren)")
    ap.add_argument("--cookies", help="Netscape cookies.txt statt Browser")
    ap.add_argument("--session-id", help="Wert des Cookies session_id")
    ap.add_argument("--no-video", action="store_true", help="Videos überspringen")
    ap.add_argument("--test", action="store_true",
                    help="Testlauf: nur die ersten 3 Posts (= --limit 3)")
    ap.add_argument("--limit", type=int, default=None,
                    help="nur die ersten N Posts laden")
    ap.add_argument("--list", action="store_true",
                    help="nur auflisten, welche Posts geladen würden (lädt nichts)")
    ap.add_argument("--delay", type=float, default=1.5, help="Pause zwischen Posts (s)")
    args = ap.parse_args()

    session = make_session(args)
    check_login(session)

    # Ziele einsammeln (Datei mit URLs oder eine URL)
    if Path(args.target).is_file():
        urls = [l.strip() for l in Path(args.target).read_text().splitlines()
                if l.strip() and not l.startswith("#")]
        course_title = Path(args.target).stem
    else:
        urls, course_title = [args.target], None

    post_ids = []
    for u in urls:
        kind, ident = parse_target(u)
        if kind == "collection":
            t, ids = collection_post_ids(session, ident)
            course_title = course_title or t
            post_ids += ids
        else:
            post_ids.append(ident)
    course_title = course_title or "Patreon-Download"
    post_ids = list(dict.fromkeys(post_ids))   # Duplikate raus, Reihenfolge bleibt
    total = len(post_ids)

    if args.list:
        log(f"Kurs: {course_title} – {total} Posts")
        for idx, pid in enumerate(post_ids, 1):
            t = fetch_post(session, pid)["data"]["attributes"].get("title")
            log(f"  {idx:03d}  {t}  (id {pid})")
            time.sleep(args.delay)
        return

    limit = args.limit or (3 if args.test else None)
    if limit:
        post_ids = post_ids[:limit]
        log(f"TESTLAUF: nur die ersten {len(post_ids)} von {total} Posts")

    outdir = Path(args.out).expanduser() / safe(course_title)
    outdir.mkdir(parents=True, exist_ok=True)
    cookiefile = outdir / ".cookies.txt"
    write_cookiefile(session, cookiefile)
    log(f"Kurs: {course_title} – {len(post_ids)} Posts → {outdir}")

    entries, failures = [], []
    try:
        for idx, pid in enumerate(post_ids, 1):
            try:
                folder, title, errs = process_post(session, pid, outdir, idx, args, cookiefile)
                entries.append((folder, title, errs))
                failures += [f"{idx:03d} {title}: {e}" for e in errs]
            except Exception as e:
                log(f"\n[{idx:03d}] Post {pid} FEHLER: {e}")
                failures.append(f"{idx:03d} Post {pid}: {e}")
            write_index(outdir, course_title, entries)   # nach jedem Post aktuell halten
            time.sleep(args.delay)
    finally:
        cookiefile.unlink(missing_ok=True)   # Session-Cookie nicht liegen lassen

    fail_file = outdir / "failures.txt"
    if failures:
        fail_file.write_text("\n".join(failures) + "\n")
        log(f"\nFertig mit {len(failures)} Fehler(n) → {fail_file}"
            "\nEinfach nochmal starten: Vorhandenes wird übersprungen.")
    else:
        fail_file.unlink(missing_ok=True)
        log(f"\nFertig ✓  Öffnen: {outdir / 'index.html'}")


if __name__ == "__main__":
    main()
