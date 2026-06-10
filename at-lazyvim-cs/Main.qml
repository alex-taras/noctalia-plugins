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
          bind("Ctrl + h/j/k/l", "Move to left / lower / upper / right window", "n"),
          bind("Ctrl + Up/Down", "Increase / decrease window height", "n"),
          bind("Ctrl + Left/Right", "Decrease / increase window width", "n"),
          bind("Space + -", "Split window below", "n"),
          bind("Space + |", "Split window right", "n"),
          bind("Space + w + d", "Delete window", "n"),
          bind("Space + w + m", "Toggle zoom mode", "n")
        ]
      },
      {
        "title": "BUFFER NAVIGATION",
        "binds": [
          bind("Shift + h / Shift + l", "Previous / next buffer", "n"),
          bind("[b / ]b", "Previous / next buffer", "n"),
          bind("Space + ,", "Open buffer picker", "n"),
          bind("Space + b + b", "Switch to other buffer", "n"),
          bind("Space + b + d", "Delete buffer", "n"),
          bind("Space + b + o", "Delete other buffers", "n"),
          bind("Space + b + p", "Toggle buffer pin", "n")
        ]
      },
      {
        "title": "FILE NAVIGATION",
        "binds": [
          bind("Space + Space", "Find files in root directory", "n"),
          bind("Space + f + f", "Find files in root directory", "n"),
          bind("Space + f + F", "Find files in current directory", "n"),
          bind("Space + f + g", "Find Git-tracked files", "n"),
          bind("Space + f + r", "Recent files", "n"),
          bind("Space + f + n", "Create a new file", "n")
        ]
      },
      {
        "title": "EXPLORER / TREE",
        "binds": [
          bind("Space + e", "Open file explorer at project root", "n")
        ]
      },
      {
        "title": "SEARCH",
        "binds": [
          bind("n / N", "Next / previous search result", "n"),
          bind("Space + /", "Grep in root directory", "n"),
          bind("Space + s + g", "Grep in root directory", "n"),
          bind("Space + s + w", "Search visual selection or word in root", "n x"),
          bind("Space + s + r", "Search and replace", "n x"),
          bind("Space + s + s", "LSP document symbols", "n")
        ]
      },
      {
        "title": "CODE / LSP NAVIGATION",
        "binds": [
          bind("g + d", "Go to definition", "n"),
          bind("g + r", "References", "n"),
          bind("g + I", "Go to implementation", "n"),
          bind("g + y", "Go to type definition", "n"),
          bind("K", "Hover documentation", "n"),
          bind("g + K / Ctrl + k", "Signature help", "n i")
        ]
      },
      {
        "title": "CODE ACTIONS",
        "binds": [
          bind("Space + c + a", "Code action", "n x"),
          bind("Space + c + r", "Rename symbol", "n"),
          bind("Space + c + f", "Format buffer or selection", "n x")
        ]
      },
      {
        "title": "DIAGNOSTICS",
        "binds": [
          bind("Space + c + d", "Line diagnostics", "n"),
          bind("]d / [d", "Next / previous diagnostic", "n"),
          bind("]e / [e", "Next / previous error", "n"),
          bind("]w / [w", "Next / previous warning", "n"),
          bind("Space + s + d", "Workspace diagnostics", "n"),
          bind("Space + s + D", "Buffer diagnostics", "n"),
          bind("Space + x + x", "Diagnostics with Trouble", "n")
        ]
      },
      {
        "title": "GIT",
        "binds": [
          bind("Space + g + s", "Git status", "n"),
          bind("Space + g + d", "Git diff hunks", "n"),
          bind("Space + g + D", "Git diff against origin", "n"),
          bind("Space + g + b", "Git blame current line", "n"),
          bind("Space + g + l", "Git log", "n"),
          bind("Space + g + f", "Current file history", "n"),
          bind("Space + g + B", "Open Git browser", "n x")
        ]
      },
      {
        "title": "TERMINAL / SESSIONS",
        "binds": [
          bind("Space + f + t", "Terminal in root directory", "n"),
          bind("Space + f + T", "Terminal in current directory", "n"),
          bind("Ctrl + /", "Toggle terminal in root directory", "n t"),
          bind("Space + q + s", "Restore session", "n"),
          bind("Space + q + l", "Restore last session", "n"),
          bind("Space + q + d", "Do not save current session", "n"),
          bind("Space + q + q", "Quit all", "n")
        ]
      },
      {
        "title": "EDITING",
        "binds": [
          bind("j / k", "Down / up, including wrapped lines", "n x"),
          bind("Alt + j / Alt + k", "Move line or selection down / up", "n i v"),
          bind("Esc", "Escape and clear search highlight", "i n s"),
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
          bind("Space + l", "Open Lazy plugin manager", "n"),
          bind("Space + ?", "Show buffer keymaps with which-key", "n")
        ]
      },
      {
        "title": "TOGGLES",
        "binds": [
          bind("Space + u + f", "Toggle auto format globally", "n"),
          bind("Space + u + F", "Toggle auto format for buffer", "n"),
          bind("Space + u + s", "Toggle spelling", "n"),
          bind("Space + u + w", "Toggle word wrap", "n"),
          bind("Space + u + l", "Toggle line numbers", "n"),
          bind("Space + u + L", "Toggle relative line numbers", "n"),
          bind("Space + u + d", "Toggle diagnostics", "n"),
          bind("Space + u + C", "Open colorschemes", "n")
        ]
      }
    ];
  }
}
