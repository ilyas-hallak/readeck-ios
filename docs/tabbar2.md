# Prompt für KI-Agent zur Überprüfung und Modernisierung einer bestehenden TabView mit NavigationStacks in SwiftUI (iOS 26)

---

## Ziel

Prüfe eine existierende SwiftUI-App mit bestehender `TabView` und `NavigationStacks` auf iOS 26-Konformität und korrigiere sie gegebenenfalls. Hauptpunkte:

- Die `TabView` soll mit moderner iOS 26 Tab-API aufgebaut sein, d.h. Tabs als eigenständige `Tab`-Views und KEIN `.tabItem` mehr verwenden.
- Jeder Tab soll eine eigene `NavigationStack` mit eigenem `NavigationPath` haben, um den Navigationszustand pro Tab unabhängig zu verwalten.
- Der Tab-Auswahl-Binding (`@State`) und `.tag()`-Zuweisungen müssen korrekt gesetzt sein.
- Der neue Such-Tab soll als `Tab(role: .search)` implementiert sein mit einem eigenen Suchfeld via `.searchable()`.
- Navigationstitel, Suchfunktion und Navigationslinks müssen in der jeweiligen NavigationStack-Umgebung eingebettet sein.
- Die TabBar soll beim Tiefennavigieren in einem Tab sichtbar bleiben, außer es gibt ein explizites Ausblenden.
- Eventuelle veraltete oder falsche Patterns wie `.tabItem` oder kombiniert verwendete `NavigationView` außerhalb der Stacks sollen korrigiert werden.
- Alle Subviews sollen modular organisiert sein und keine Globalzustände die Navigation verwalten.

---

## Prüffragen für den Agenten

1. Nutzt die `TabView` die neue Form mit `Tab` als Container pro Tab?
2. Werden für jeden Tab eigene `NavigationStack`s und `NavigationPath`s verwendet?
3. Sind `.tag()` und `selection` in `TabView` korrekt implementiert?
4. Ist der Such-Tab mit `Tab(role: .search)` sauber getrennt und die Suche mit `.searchable()` eingebunden?
5. Werden veraltete `.tabItem` Modifier vollständig entfernt?
6. Bleibt die TabBar sichtbar beim Navigieren in den Stacks, außer bewusst ausgeblendet?
7. Wird State sauber und lokal in den jeweiligen Views verwaltet?
8. Gibt es keine vermischten oder redundanten NavigationView/Stacks?
9. Werden Navigationsziele übersichtlich in Subviews ausgelagert?
10. Ist der gesamte Code idiomatisch und an die iOS 26 SwiftUI-Standards angepasst?

---

## Ausgabeformat

Der Agent soll die App prüfen, Fehler auflisten, Korrekturen vorschlagen und wenn möglich direkt umgesetzten SwiftUI-Code erzeugen, der:

- Komplette TabView mit Tabs als `Tab`
- Jeweils eigene NavigationStack mit NavigationPath
- Such-Tab mit `Tab(role: .search)` und suchbarer Navigation
- Keine `.tabItem` oder deprecated Patterns enthält
- Klar strukturiert und modular ist

---

## Beispiel-Ausschnitt zur Referenz
```swift

TabView(selection: $selectedTab) {Tab(“Home”, systemImage: “house”) {NavigationStack(path: $homePath) {HomeView()}}.tag(Tab.home)

Tab(role: .search) {
    NavigationStack(path: $searchPath) {
        SearchView()
            .searchable(text: $searchText)
            .navigationTitle("Search")
    }
}
.tag(Tab.search)

// weitere Tabs...

}
```
---

