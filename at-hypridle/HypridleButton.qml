import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
  id: root

  // Plugin API (injected by PluginService)
  property var pluginApi: null

  // Required properties for bar widgets
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  // State
  property bool hypridleRunning: false
  property bool checking: false

  readonly property color activeColor: "#4ade80"  // green when running
  readonly property color inactiveColor: "#f87171"  // red when stopped
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name || "")

  implicitWidth: button.implicitWidth
  implicitHeight: Style.barHeight

  // Check if hypridle is running on startup
  Component.onCompleted: {
    checkStatus()
  }

  // Periodically check hypridle status
  Timer {
    interval: 2000  // Check every 2 seconds
    running: true
    repeat: true
    onTriggered: {
      checkStatus()
    }
  }

  function checkStatus() {
    if (!checking) {
      statusChecker.running = true
    }
  }

  function toggleHypridle() {
    hypridleToggler.running = true
  }

  // Process to check if hypridle is running
  Process {
    id: statusChecker
    command: ["pgrep", "-x", "hypridle"]
    running: false

    onStarted: {
      root.checking = true
    }

    onExited: (code, status) => {
      root.checking = false
      // pgrep returns 0 if process found, 1 if not found
      root.hypridleRunning = (code === 0)
    }
  }

  // Process to toggle hypridle
  Process {
    id: hypridleToggler
    command: ["/home/alext/bin/toggle-hypridle"]
    running: false

    onExited: () => {
      // Wait a bit then check status
      recheckTimer.start()
    }
  }

  // Timer to recheck status after toggle
  Timer {
    id: recheckTimer
    interval: 500
    repeat: false
    onTriggered: {
      checkStatus()
    }
  }

  Rectangle {
    id: button
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: buttonRow.implicitWidth + Style.marginM * 2
    height: capsuleHeight

    color: Style.capsuleColor
    radius: Style.radiusM

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.toggleHypridle()
      }
    }

    RowLayout {
      id: buttonRow
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        icon: "system-lock-screen"
        color: root.hypridleRunning ? root.activeColor : root.inactiveColor
        pointSize: Style.fontSizeM
      }

      NText {
        text: root.hypridleRunning ? "ON" : "OFF"
        color: root.hypridleRunning ? root.activeColor : root.inactiveColor
        pointSize: Style.fontSizeS
        font.bold: true
      }
    }
  }
}
