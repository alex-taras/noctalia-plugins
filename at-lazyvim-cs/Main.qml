import QtQuick

Item {
  id: root

  property var pluginApi: null
  property int cheatsheetDataVersion: 0
  property var cheatsheetData: buildCheatsheetData()

  function refresh() {
    cheatsheetData = buildCheatsheetData();
    cheatsheetDataVersion++;
  }

  function bind(keys, desc, modes) {
    return {
      "keys": keys,
      "desc": desc,
      "modes": modes || "n"
    };
  }

  function buildCheatsheetData() {
    return [
      {
        "title": "WINDOW NAVIGATION",
        "binds": [
          bind("Ctrl + h/j/k/l", "Move between windows", "n"),
          bind("Ctrl + Up/Down", "Resize height", "n"),
          bind("Ctrl + Left/Right", "Resize width", "n"),
          bind("Space + -", "Split below", "n"),
          bind("Space + |", "Split right", "n"),
          bind("Space + w + d", "Delete window", "n"),
          bind("Space + w + m", "Toggle zoom", "n")
        ]
      },
      {
        "title": "BUFFER NAVIGATION",
        "binds": [
          bind("Shift + h / Shift + l", "Prev / next buffer", "n"),
          bind("[b / ]b", "Prev / next buffer", "n"),
          bind("Space + ,", "Buffer picker", "n"),
          bind("Space + b + b", "Other buffer", "n"),
          bind("Space + b + d", "Delete buffer", "n"),
          bind("Space + b + o", "Delete other buffers", "n"),
          bind("Space + b + p", "Pin buffer", "n")
        ]
      },
      {
        "title": "FILE NAVIGATION",
        "binds": [
          bind("Space + Space", "Find root files", "n"),
          bind("Space + f + f", "Find root files", "n"),
          bind("Space + f + F", "Find local files", "n"),
          bind("Space + f + g", "Find Git-tracked files", "n"),
          bind("Space + f + r", "Recent files", "n"),
          bind("Space + f + n", "New file", "n")
        ]
      },
      {
        "title": "EXPLORER / TREE",
        "binds": [
          bind("Space + e", "Open project explorer", "n")
        ]
      },
      {
        "title": "SEARCH",
        "binds": [
          bind("n / N", "Next / previous match", "n"),
          bind("Space + /", "Grep root", "n"),
          bind("Space + s + g", "Grep root", "n"),
          bind("Space + s + w", "Search word / selection", "n x"),
          bind("Space + s + r", "Search and replace", "n x"),
          bind("Space + s + s", "Document symbols", "n")
        ]
      },
      {
        "title": "CODE / LSP NAVIGATION",
        "binds": [
          bind("g + d", "Definition", "n"),
          bind("g + r", "References", "n"),
          bind("g + I", "Implementation", "n"),
          bind("g + y", "Type definition", "n"),
          bind("K", "Hover docs", "n"),
          bind("g + K / Ctrl + k", "Signature help", "n i")
        ]
      },
      {
        "title": "CODE ACTIONS",
        "binds": [
          bind("Space + c + a", "Actions", "n x"),
          bind("Space + c + r", "Rename", "n"),
          bind("Space + c + f", "Format", "n x")
        ]
      },
      {
        "title": "DIAGNOSTICS",
        "binds": [
          bind("Space + c + d", "Line diagnostic", "n"),
          bind("]d / [d", "Next / previous diagnostic", "n"),
          bind("]e / [e", "Next / previous error", "n"),
          bind("]w / [w", "Next / previous warning", "n"),
          bind("Space + s + d", "Workspace diagnostics", "n"),
          bind("Space + s + D", "Buffer diagnostics", "n"),
          bind("Space + x + x", "Trouble diagnostics", "n")
        ]
      },
      {
        "title": "GIT",
        "binds": [
          bind("Space + g + s", "Git status", "n"),
          bind("Space + g + d", "Diff hunks", "n"),
          bind("Space + g + D", "Diff origin", "n"),
          bind("Space + g + b", "Blame line", "n"),
          bind("Space + g + l", "Git log", "n"),
          bind("Space + g + f", "File history", "n"),
          bind("Space + g + B", "Git browser", "n x")
        ]
      },
      {
        "title": "TERMINAL / SESSIONS",
        "binds": [
          bind("Space + f + t", "Root terminal", "n"),
          bind("Space + f + T", "Local terminal", "n"),
          bind("Ctrl + /", "Toggle terminal", "n t"),
          bind("Space + q + s", "Restore session", "n"),
          bind("Space + q + l", "Restore last", "n"),
          bind("Space + q + d", "Skip session save", "n"),
          bind("Space + q + q", "Quit all", "n")
        ]
      },
      {
        "title": "EDITING",
        "binds": [
          bind("j / k", "Move by screen line", "n x"),
          bind("Alt + j / Alt + k", "Move line / selection", "n i v"),
          bind("Esc", "Escape and clear search", "i n s"),
          bind("Ctrl + s", "Save file", "i x n s"),
          bind("g + c + o", "Add comment below", "n"),
          bind("g + c + O", "Add comment above", "n")
        ]
      },
      {
        "title": "UI / LAZYVIM",
        "binds": [
          bind("Space + Tab + Tab", "New tab", "n"),
          bind("Space + Tab + ]", "Next tab", "n"),
          bind("Space + Tab + [", "Previous tab", "n"),
          bind("Space + Tab + d", "Close tab", "n"),
          bind("Space + L", "LazyVim changelog", "n"),
          bind("Space + l", "Lazy plugin manager", "n"),
          bind("Space + ?", "Buffer keymaps", "n")
        ]
      },
      {
        "title": "TOGGLES",
        "binds": [
          bind("Space + u + f", "Auto format", "n"),
          bind("Space + u + F", "Buffer auto format", "n"),
          bind("Space + u + s", "Toggle spelling", "n"),
          bind("Space + u + w", "Toggle word wrap", "n"),
          bind("Space + u + l", "Toggle line numbers", "n"),
          bind("Space + u + L", "Relative numbers", "n"),
          bind("Space + u + d", "Toggle diagnostics", "n"),
          bind("Space + u + C", "Colorschemes", "n")
        ]
      }
    ];
  }
}
