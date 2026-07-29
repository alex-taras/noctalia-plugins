# LazyVim Cheatsheet

A Noctalia plugin that displays a searchable LazyVim shortcut cheatsheet in a compact panel.

The shortcut data comes from `lazyvim-keyshortcuts.html`, then is regrouped by workflow: window navigation, buffer navigation, file navigation, explorer/tree, search, code/LSP, diagnostics, Git, sessions, editing, UI, and toggles.

## Desktop widget

`DesktopWidget.qml` adds the cheatsheet to the desktop (Settings → Desktop Widgets → add `LazyVim Cheatsheet`).

It starts collapsed as a narrow strip showing only the essentials: basic editing (cursor motions, line motions, entering insert mode, undo/save) and buffer navigation. Click the header to expand.

Expanded, it embeds `Panel.qml` — the same content as the bar panel, with its columns, search box, mode filters and working settings button. It uses the same size the bar panel does, from the plugin's own `windowWidth` / `windowHeight` / `autoHeight` / `columnCount` settings, clamped to 90% of the screen. It centers itself on the monitor when expanded, and returns to where the strip was when collapsed. The chevron at the bottom-right collapses it again.

The collapsed/expanded state is stored per widget instance, so two instances on the same desktop can differ. Per-instance keys in the widget data: `collapsed`, `showModes`, `desktopWidth`, `desktopMaxHeight`, plus the standard `showBackground` and `roundedCorners`.

Colors are resolved from Noctalia theme tokens by default. Manifest color settings are empty-string overrides so the default behavior remains theme-aware.
