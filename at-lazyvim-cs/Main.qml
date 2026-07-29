import QtQuick

Item {
  id: root

  property var pluginApi: null
  property int cheatsheetDataVersion: 0
  property var cheatsheetData: buildCheatsheetData()
  property var compactData: buildCompactData()

  function refresh() {
    cheatsheetData = buildCheatsheetData();
    compactData = buildCompactData();
    cheatsheetDataVersion++;
  }

  function bind(keys, desc, modes) {
    return {
      "keys": keys,
      "desc": desc,
      "modes": modes || "n"
    };
  }

  // Minimal set shown by the desktop widget while collapsed:
  // line/word motions, entering insert mode and moving between buffers.
  function buildCompactData() {
    return [
      {
        "title": "BASIC EDITING",
        "binds": [
          bind("h/j/k/l", "Move cursor", "n x"),
          bind("w / b", "Next / previous word", "n x"),
          bind("0 / $", "Line start / end", "n x"),
          bind("gg / G", "File start / end", "n x"),
          bind("i / a", "Insert before / after", "n"),
          bind("o / O", "Open line below / above", "n"),
          bind("dd / yy", "Delete / copy line", "n"),
          bind("u / Ctrl + r", "Undo / redo", "n"),
          bind("Esc", "Back to normal mode", "i n s"),
          bind("Ctrl + s", "Save file", "i x n s")
        ]
      },
      {
        "title": "BUFFER NAVIGATION",
        "binds": [
          bind("Shift + h / Shift + l", "Prev / next buffer", "n"),
          bind("Space + ,", "Buffer picker", "n"),
          bind("Space + b + b", "Other buffer", "n"),
          bind("Space + b + d", "Delete buffer", "n")
        ]
      }
    ];
  }

  function buildCheatsheetData() {
    return [
      {
        "title": "EDITING",
        "binds": [
          bind("i / a", "Insert before / after", "n"),
          bind("I / A", "Insert line start / end", "n"),
          bind("o / O", "Open line below / above", "n"),
          bind("Esc", "Escape and clear search", "i n s"),
          bind("Ctrl + s", "Save file", "i x n s"),
          bind("h/j/k/l", "Move cursor", "n x"),
          bind("j / k", "Move by screen line", "n x"),
          bind("w / b", "Next / previous word", "n x"),
          bind("e / ge", "Next / previous word end", "n x"),
          bind("0 / $", "Line start / end", "n x"),
          bind("^ / g_", "First / last text", "n x"),
          bind("gg / G", "File start / end", "n x"),
          bind("dd", "Delete line", "n"),
          bind("D", "Delete to line end", "n"),
          bind("dw / db", "Delete word forward / back", "n"),
          bind("x / X", "Delete char forward / back", "n"),
          bind("cc", "Change line", "n"),
          bind("cw / ciw", "Change word", "n"),
          bind("r", "Replace char", "n"),
          bind("J", "Join line below", "n"),
          bind("yy", "Copy line", "n"),
          bind("yw / yiw", "Copy word", "n"),
          bind("p / P", "Paste after / before", "n"),
          bind("u / Ctrl + r", "Undo / redo", "n"),
          bind(".", "Repeat last change", "n"),
          bind("f / F", "Find char forward / back", "n x"),
          bind("%", "Matching pair", "n x"),
          bind("* / #", "Search word forward / back", "n"),
          bind("v / V", "Visual char / line", "n"),
          bind("y / d / c", "Copy / delete / change selection", "x"),
          bind("> / <", "Indent selection", "x"),
          bind("g + c + o", "Add comment below", "n"),
          bind("g + c + O", "Add comment above", "n"),
          bind("Alt + j / Alt + k", "Move line / selection", "n i v")
        ]
      },
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
