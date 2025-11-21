## Feature: TabView nur in Root-Screens sichtbar, nicht in Detail-Views

### Beschreibung
Die App verwendet aktuell eine `TabView` (bzw. einen Tab Controller), die global sichtbar ist.  
Der Workflow funktioniert grundsätzlich, allerdings wird die `TabView` auch dann angezeigt, wenn ein Benutzer von einem Tab in eine **Detailansicht** (z. B. Artikel-Detail, Item-Detail) navigiert.  

Ziel ist es, dass die `TabView` **nur in den Root-Views** sichtbar ist.  
Beim Öffnen einer **Detail-Ansicht** soll die `TabView` automatisch ausgeblendet werden, damit dort alternativ eine eigene **Bottom Toolbar** angezeigt werden kann.

### Akzeptanzkriterien
- `TabView` ist standardmäßig in den Haupt-Tabs sichtbar.
- Navigiert der Nutzer in eine Detail-Ansicht (z. B. Rom Detail), wird die `TabView` ausgeblendet.
- In den Detail-Ansichten kann ein eigener `Toolbar` oder eine Custom Bottom Bar sichtbar sein - ist aber kein teil von diesem task.
- Navigation zurück zur Root-View blendet die `TabView` wieder ein.

# Technischer hinweis

To hide TabBar when we jumps towards next screen we just have to place NavigationView to the right place. Makesure Embed TabView inside NavigationView so creating unique Navigationview for both tabs. 