# LazyVim Cheatsheet

A Noctalia plugin that displays a searchable LazyVim shortcut cheatsheet in a compact panel.

The shortcut data comes from `lazyvim-keyshortcuts.html`, then is regrouped by workflow: window navigation, buffer navigation, file navigation, explorer/tree, search, code/LSP, diagnostics, Git, sessions, editing, UI, and toggles.

## Desktop widget

`DesktopWidget.qml` adds the cheatsheet to the desktop (Settings → Desktop Widgets → add `LazyVim Cheatsheet`).

It starts collapsed, showing only the essentials: basic editing (cursor motions, line motions, entering insert mode, undo/save) and buffer navigation. Click the header to expand it into the full category list; the content scrolls once it exceeds the widget height. The collapsed/expanded state is stored per widget instance, so two instances on the same desktop can differ.

Per-instance keys in the widget data: `collapsed`, `showModes`, `desktopWidth`, `desktopMaxHeight`, plus the standard `showBackground` and `roundedCorners`.

Colors are resolved from Noctalia theme tokens by default. Manifest color settings are empty-string overrides so the default behavior remains theme-aware.
