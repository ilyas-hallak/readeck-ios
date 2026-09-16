# Readeck-Server: API-Kompatibilität

Grundlage für das Capability-Mapping in `readeck/Domain/Model/` (`SemanticVersion`, `ServerCapabilities`).
Wer eine Versionsgrenze im Code ändert, sollte sie hier belegen können.

Stand der Recherche: 2026-09-04, gegen Upstream-Tag `0.23.2` auf https://codeberg.org/readeck/readeck.
Referenzinstanz: readeck.ilyashallak.de (0.23.2).

## Support-Floor: 0.20.2

Begründung der Untergrenze:

- Unter 0.20.0 gibt es `GET /api/info` nicht (404).
  Die Serverversion ist damit nicht abfragbar, Capabilities könnten nur durch Endpunkt-Probing geraten werden.
- 0.20.0 und 0.20.1 sind für schreibende Requests defekt.
  Die in 0.20.0 eingeführte Go-1.25-CSRF-Protection verlor die Ausnahme für token-authentifizierte Requests, POST/PATCH/DELETE scheitern mit 403.
  Repariert in 0.20.2 (Commit `f995a1af`: "This restores the behavior from before 0.20").

Diese beiden Versionen werden deshalb aktiv als defekt erkannt (`isKnownBrokenForWrites`), statt den Nutzer in stille 403er laufen zu lassen.

## Warum das `features`-Array nicht als Capability-Quelle taugt

`GET /api/info` liefert ab 0.21.0 ein `features`-Array.
Es sieht wie ein Discovery-Mechanismus aus, trägt aber kaum Information.
Aus `internal/server/server.go`:

```go
Features: []string{
    "oauth",
},
...
if auth.HasPermission(r.Context(), "email", "send") {
    res.Features = append(res.Features, "email")
}
```

- `"oauth"` ist hartcodiert und ab 0.21.0 immer gesetzt.
  Es sagt ausschließlich "Server >= 0.21.0" aus, nicht ob OAuth nutzbar oder konfiguriert ist.
- `"email"` ist request-abhängig, nicht instanz-abhängig.
  Es erscheint nur, wenn der aufrufende Request die Permission `email:send` besitzt.
  Ein unauthentifizierter Aufruf von `/api/info` liefert es systematisch nie.
- Mehr als diese zwei Werte gibt es nicht (`enum: [email, oauth]` in `docs/api/info/routes.yaml`).

Konsequenzen für den Client:

1. Tragende Quelle für Feature-Gates ist `version.canonical` per Semver-Vergleich.
2. `features` wird nur für `email` ausgewertet, und nur bei authentifizierter Abfrage.
3. OAuth-Verfügbarkeit wird über `/.well-known/oauth-authorization-server` (RFC 8414) ermittelt.

Eine offizielle Upstream-Empfehlung zur Capability-Erkennung existiert nicht.
Gesucht wurde in `docs/`, CHANGELOG und den Issues #166, #844, #904.

## Versionsgrenzen

| Fähigkeit | Ab Version | Beleg |
|---|---|---|
| `GET /api/info` | 0.20.0 | Commit `4b4b0a93`, vorher 404 |
| `features` in `/api/info` | 0.21.0 | Commit `06244274` |
| `POST /api/auth` (Passwort-Login) | 0.1.0 bis **0.21.6** | in 0.21.0 deprecated, in 0.22.0 entfernt (Commit `3f5f50ed`) |
| OAuth2 Auth-Code + Device-Code | 0.21.0 | `internal/auth/oauth2/` |
| `/.well-known/oauth-authorization-server` | 0.21.0 | `internal/auth/oauth2/http.go` |
| HTML-Upload bei Bookmark-Create | 0.22.0 | `forms.NewFileField("html")`, fehlt in 0.21.6 |
| Sync-API vorhanden | 0.20.0 | `api_sync.go` |
| Sync-API verlässlich | 0.22.0 | Datums-Bug bis 0.20.x, Sortier-Bug bis 0.21.x |
| Conditional Requests (ETag) mit Token | 0.20.0 | CHANGELOG: "HTTP cache couldn't work with an API token" |
| Labels-Detail via `?name=` | 0.20.0 | vorher `/labels/{label}`, Umbau wegen Sonderzeichen in Labels |
| `PATCH` auf Annotationen (Farben) | 0.17.0 | mit "Colored highlights" |
| Annotation `note`-Feld | 0.22.0 | CHANGELOG |
| Bookmark-User-Note, `has_notes`-Filter | 0.23.0 | Commit `9f7031d5` |
| `read_progress`, `read_anchor`, `word_count`, `reading_time` | 0.17.0 | `docs/api/bookmarks/types.yaml`, fehlt in 0.16.0 |
| `read_status`, mehrwertiger `type`-Filter | 0.17.0 | CHANGELOG |
| 422 mit Fehlerobjekt bei ungültigen Filtern | 0.21.4 | CHANGELOG |
| Suche mit `*` und `-` | 0.13.0 | neuer Query-Builder, Commit `7048c526` |
| Pagination-Header (`Total-Count` usw.) | 0.1.0 | `internal/server/pagination.go`, kein Bruch |

## Auth-Historie

Der Passwort-Login wurde nicht deprecated, weil OAuth schöner ist, sondern weil er technisch unmöglich wurde.
Aus der Commit-Message von `3f5f50ed`:

> With the introduction of MFA, you can't authenticate with a username and password anymore.
> OAuth is now the only way to obtain an access token.

Daraus ergibt sich die Login-Weiche der App:

| Serverversion | Passwort-Login | OAuth |
|---|---|---|
| 0.20.2 bis 0.20.4 | ja | nein |
| 0.21.x | ja | ja |
| ab 0.22.0 | **nein** | ja |

Der Bereich ist damit lückenlos gedeckt.

Ein dritter Weg existiert, ist aber nicht implementiert:
manuell in der Web-UI erzeugte API-Tokens funktionieren per Bearer oder HTTP Basic über den gesamten Versionsbereich ab 0.18.0, auch auf 0.23.2 (zugesagt in Issue #844).
Das wäre der einzige Auth-Pfad ohne Versionsabhängigkeit und ein Ausweg, wenn der OAuth-Callback klemmt.
Bewusst zurückgestellt.

OIDC ab 0.23.0 ist für den Client irrelevant.
Readeck ist dabei OIDC *Relying Party* für den Web-UI-Login, kein OIDC-Provider.

## OAuth-Details

Die Endpunkte sollten aus `/.well-known/oauth-authorization-server` gelesen werden statt hartcodiert.
Antwort der Referenzinstanz:

| Feld | Wert |
|---|---|
| `authorization_endpoint` | `/authorize` |
| `token_endpoint` | `/api/oauth/token` |
| `device_authorization_endpoint` | `/api/oauth/device` |
| `registration_endpoint` | `/api/oauth/client` |
| `revocation_endpoint` | `/api/oauth/revoke` |
| `scopes_supported` | `bookmarks:read`, `bookmarks:write`, `profile:read` |
| `code_challenge_methods_supported` | `S256` |

Weitere Randbedingungen aus `docs/api/oauth.md`:

- Dynamische Client-Registrierung nach RFC 7591 ist Pflicht.
  Laut Doku muss vor jedem Authorization-Flow ein neuer Client registriert werden.
- PKCE ist Pflicht, ausschließlich `S256`.
  `plain` ist verboten.
- Kein `client_secret` erforderlich.
- Der Grant `refresh_token` wird **nicht** unterstützt.
  `internal/auth/oauth2/forms.go` erlaubt nur `authorization_code` und `urn:ietf:params:oauth:grant-type:device_code`.
  Die Token-Antwort enthält weder `refresh_token` noch `expires_in`, Readeck-Tokens laufen nicht ab.

## Response-Felder, die der Server weglässt

Der Server nutzt `omitempty`, die OpenAPI-Spec führt in Response-Schemata praktisch nirgends `required`.
Nicht-optionale Swift-Felder sind daher eine Bruchquelle.

| Feld | Server | Wirkung bei non-optional |
|---|---|---|
| `bookmarkResourceImage.width`, `.height` | `omitempty`, wird bei unbekannter Bildgröße weggelassen | Decoding-Fehler reißt die gesamte Bookmark-Liste mit |
| `bookmark.authors` | `nil` serialisiert zu `null` | Decoding-Fehler, praktisch durch DB-Default `'[]'` abgesichert |
| `profile.user.username` | `omitempty` | Key fehlt bei leerem Username |
| `word_count`, `reading_time`, `published`, `lang` | `omitempty` | bereits korrekt optional im Client |

## Die OpenAPI-Spec beschaffen

Die Spec ist nicht als fertige Datei im Repo eingecheckt, sondern wird generiert.
Quellen liegen unter `docs/api/` als OpenAPI-3.0-YAMLs mit einem projekteigenen `$include`/`$merge`-Präprozessor, Einstieg `docs/api/api.yaml`.
Für einen Versionsvergleich kann man diese Quellen tag-genau von Codeberg ziehen:

```
https://codeberg.org/readeck/readeck/raw/tag/<TAG>/docs/api/api.yaml
```

Eine laufende Instanz liefert die kompilierte Spec unter `GET /docs/api.json`.
Das erfordert Authentifizierung und die Permission `docs:read`, anonym ist sie nicht abrufbar.
Die auf einer Instanz naheliegenden Pfade `/api/openapi.json` und `/api/docs` existieren nicht und enden im Login-Redirect.

## Verhalten unbekannter Pfade

Nützlich zur Diagnose: der Server unterscheidet registrierte von unbekannten API-Pfaden.

- Registrierte API-Route ohne Auth: `401 Unauthorized` mit Text-Body.
- Nicht registrierter Pfad: `303 See Other` nach `/login`.

Ein `303` auf einen `/api/`-Pfad bedeutet also "diesen Endpunkt gibt es auf dieser Version nicht".
So lässt sich das Fehlen von `POST /api/auth` ab 0.22.0 gegen eine laufende Instanz verifizieren.

Wichtig für den Client: `URLSession` folgt dem 303 automatisch, bekommt die HTML-Loginseite mit Status 200 und läuft dann in einen JSON-Decoding-Fehler.
Der Nutzer sieht eine irreführende Formatfehlermeldung statt "Endpunkt nicht verfügbar".
Deshalb muss der Content-Type der Antwort geprüft werden, bevor dekodiert wird.
