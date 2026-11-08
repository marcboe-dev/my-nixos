gcc -g -Wall -Wextra main.c -o main    kompilieren mit debug-infos (macht F11 automatisch)

## Start
F11                 quick debug: speichern, kompilieren, starten (aktuelle .c datei)
                    debug-counter.c → binary debug-counter im selben ordner
leader+bm           launch-menü (mit argumenten, attach an prozess, anderes executable)
leader+br           letzte session neu starten (ohne neu kompilieren)
leader+bW           compiler-warnungen an/aus (aus = ohne hinweise üben)

## Steppen (F9-F12 liegen wie h j k l)
F9                  step out      (h, ←)  raus aus der funktion  = gdb finish
F10                 step over     (j, ↓)  nächste zeile          = gdb next
F11                 continue      (k, ↑)  bis zum nächsten breakpoint
F12                 step into     (l, →)  rein in die funktion   = gdb step
leader+bC           bis zur cursor-zeile laufen

## Breakpoints
F8                  breakpoint an/aus
leader+bb           breakpoint an/aus
leader+bc           breakpoint mit bedingung (zB i == 5)
leader+bl           logpoint, gibt text aus ohne anzuhalten (zB i={i})
leader+bx           alle breakpoints löschen

## Variablen
leader+be           wert unter cursor im float anzeigen
leader+bE           wert anzeigen + in float springen (structs aufklappen)

## Fenster
←/↓/↑/→             fenster wechseln
leader+z            aktuelles fenster groß als float (nochmal = zu)
leader+bu           dap-ui ein/aus

## In dap-ui fenstern
enter               aufklappen / zum frame springen
t                   breakpoint an/aus (breakpoints)
e                   wert bearbeiten (scopes)
d                   watch löschen (watches)
i                   neuen watch / repl-eingabe

## Die fenster
scopes              alle variablen (local, static, global)
breakpoints         liste aller breakpoints
stacks              aufrufkette, enter springt in den frame
watches             eigene ausdrücke beobachten (zB *value)
repl                mit dem debugger reden
console             terminal des programms (printf ausgabe, scanf eingabe)
                    label steht UNTER dem fenster, nicht darüber

## REPL (lldb befehle)
.next .into .out    steppen per text
.continue
frame variable      alle lokalen variablen
p <ausdruck>        ausdruck auswerten (zB p &counter)

## Beenden
leader+bq           session beenden
ctrl+^              zurück zur letzten datei (falls assembler hängen bleibt)
:b#                 dasselbe, falls ctrl+^ nicht geht
ctrl+\ ctrl+n       terminal-modus verlassen (console)

## Wichtig
F8 vor F11              ohne breakpoint läuft das programm einfach durch
assembler statt code    programm steht in libc → stacks: eigenen frame wählen
nach return 0 weiter    landet in libc-startcode → F11 statt F10 zum beenden
kein stopp beim fehler  debugger hält nur bei breakpoint oder crash
breakpoint ○            ohne -g kompiliert oder binary veraltet
warnungen bei erfolg    werden kurz angezeigt, debugger startet trotzdem
