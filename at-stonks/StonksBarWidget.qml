import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import "." as Local

Item {
  id: root

  // Plugin API (injected by PluginService)
  property var pluginApi: null

  // Required properties for bar widgets
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  // Settings
  property var settings: ({})
  property string settingsBuffer: ""
  property int maxWidth: 300
  property bool autoScroll: true

  // i18n
  property var i18n: ({})
  property string i18nBuffer: ""

  readonly property color upColor: "#4ade80"  // green
  readonly property color downColor: Color.mError
  readonly property color neutralColor: Color.mOnSurface

  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name || "")

  // Dynamic width - use content width if smaller than maxWidth, otherwise use maxWidth
  readonly property int contentWidth: container.visible ? (contentRow.implicitWidth + Style.marginM * 2) : maxWidth
  readonly property int actualWidth: contentWidth > 0 ? Math.min(contentWidth, maxWidth) : maxWidth

  implicitWidth: actualWidth
  implicitHeight: Style.barHeight

  // Load i18n translations
  Process {
    id: i18nLoader
    command: ["cat", Qt.resolvedUrl("i18n/" + (Settings.data.locale || "en") + ".json").toString().replace("file://", "")]
    running: true

    stdout: SplitParser {
      onRead: data => {
        root.i18nBuffer += data
      }
    }

    onExited: () => {
      try {
        root.i18n = JSON.parse(root.i18nBuffer)
      } catch (e) {
        // Fallback to English
        i18nFallback.running = true
      }
    }
  }

  // Fallback to English if locale file not found
  Process {
    id: i18nFallback
    command: ["cat", Qt.resolvedUrl("i18n/en.json").toString().replace("file://", "")]

    stdout: SplitParser {
      onRead: data => {
        root.i18nBuffer += data
      }
    }

    onExited: () => {
      try {
        root.i18n = JSON.parse(root.i18nBuffer)
      } catch (e) {
        // Silent fail, use hardcoded strings
      }
    }
  }

  // Timer to poll for settings changes
  Timer {
    interval: 1000 // Check every second
    running: true
    repeat: true
    onTriggered: {
      settingsLoader.running = true
    }
  }

  // Load settings
  Process {
    id: settingsLoader
    command: ["cat", Qt.resolvedUrl("settings.json").toString().replace("file://", "")]

    property string tempBuffer: ""

    stdout: SplitParser {
      onRead: data => {
        settingsLoader.tempBuffer += data
      }
    }

    onExited: () => {
      try {
        const newSettings = JSON.parse(tempBuffer)
        tempBuffer = ""

        // Check if settings actually changed to avoid unnecessary updates
        const settingsChanged = JSON.stringify(newSettings) !== JSON.stringify(root.settings)

        if (settingsChanged) {
          root.settings = newSettings

          if (root.settings.width) {
            root.maxWidth = root.settings.width
          }

          if (root.settings.hasOwnProperty("autoscroll")) {
            root.autoScroll = root.settings.autoscroll
          }
        }
      } catch (e) {
        Logger.e("Stonks", "Failed to parse settings: " + e)
        tempBuffer = ""
      }
    }
  }

  Rectangle {
    id: container
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.actualWidth
    height: capsuleHeight

    color: Style.capsuleColor
    radius: Style.radiusM
    clip: true

  Item {
    anchors.fill: parent
    anchors.leftMargin: Style.marginM
    anchors.rightMargin: Style.marginM
    clip: true

    property bool needsScroll: (contentRow.implicitWidth + Style.marginM * 2) > root.maxWidth

    Row {
      id: scrollContainer
      height: parent.height

      NumberAnimation on x {
        id: scrollAnimation
        running: false
        from: 0
        to: -contentRow.implicitWidth
        duration: contentRow.implicitWidth * 15
        loops: Animation.Infinite
        easing.type: Easing.Linear
      }

      function checkAndStartScroll() {
        const shouldScroll = scrollContainer.parent.needsScroll && root.autoScroll

        if (shouldScroll) {
          scrollAnimation.start()
        } else {
          scrollAnimation.stop()
          scrollContainer.x = 0
        }
      }

      Component.onCompleted: {
        checkAndStartScroll()
        // Recheck after a short delay to ensure stocks are loaded
        recheckTimer.start()
      }

      Timer {
        id: recheckTimer
        interval: 500
        repeat: true
        running: false
        triggeredOnStart: false
        onTriggered: {
          scrollContainer.checkAndStartScroll()
          // Stop after a few attempts
          if (Local.StonksService.stocks && Object.keys(Local.StonksService.stocks).length > 0) {
            stop()
          }
        }
      }

      Connections {
        target: root
        function onAutoScrollChanged() {
          scrollContainer.checkAndStartScroll()
        }
      }

      Connections {
        target: Local.StonksService
        function onStocksChanged() {
          scrollContainer.checkAndStartScroll()
        }
      }

      RowLayout {
        id: contentRow
        height: parent.height
        spacing: Style.marginS

        onImplicitWidthChanged: {
          scrollContainer.checkAndStartScroll()
        }

      Repeater {
        model: Local.StonksService.stocks ? Object.keys(Local.StonksService.stocks) : []

        RowLayout {
          spacing: Style.marginXS

          property var stock: Local.StonksService.stocks[modelData]
          property bool isLast: index === (Local.StonksService.stocks ? Object.keys(Local.StonksService.stocks).length - 1 : 0)

          NText {
            text: modelData
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
          }

          NText {
            id: priceText
            property real change: parent.stock ? parent.stock.change : 0
            text: "$" + (parent.stock ? parent.stock.price : "")
            color: {
              if (change > 0) return root.upColor
              if (change < 0) return root.downColor
              return root.neutralColor
            }
            pointSize: Style.fontSizeS
          }

          NText {
            text: "("
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
          }

          NText {
            id: deltaText
            property real change: parent.stock ? parent.stock.change : 0
            text: (change >= 0 ? "+" : "") + change.toFixed(2)
            color: {
              if (change > 0) return root.upColor
              if (change < 0) return root.downColor
              return root.neutralColor
            }
            pointSize: Style.fontSizeS
          }

          NText {
            text: ")"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
          }

          NText {
            visible: !parent.isLast
            text: " | "
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
          }
        }
      }

      NText {
        visible: !Local.StonksService.stocks || Object.keys(Local.StonksService.stocks).length === 0
        text: {
          if (Local.StonksService.loading) {
            return root.i18n?.widget?.loading || "Loading..."
          } else {
            return root.i18n?.widget?.configure || "Please configure your symbols"
          }
        }
        color: Color.mOnSurface
        pointSize: Style.fontSizeS
      }
    }

    // Separator between original and duplicate
    NText {
      visible: parent.parent.needsScroll
      text: " | "
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeS
      anchors.verticalCenter: parent.verticalCenter
    }

    // Duplicate for seamless loop
    RowLayout {
      height: parent.height
      spacing: Style.marginS
      visible: parent.parent.needsScroll

      Repeater {
        model: Local.StonksService.stocks ? Object.keys(Local.StonksService.stocks) : []

        RowLayout {
          spacing: Style.marginXS

          property var stock: Local.StonksService.stocks[modelData]
          property bool isLast: index === (Local.StonksService.stocks ? Object.keys(Local.StonksService.stocks).length - 1 : 0)

          NText {
            text: modelData
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
          }

          NText {
            property real change: parent.stock ? parent.stock.change : 0
            text: "$" + (parent.stock ? parent.stock.price : "")
            color: {
              if (change > 0) return root.upColor
              if (change < 0) return root.downColor
              return root.neutralColor
            }
            pointSize: Style.fontSizeS
          }

          NText {
            text: "("
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
          }

          NText {
            property real change: parent.stock ? parent.stock.change : 0
            text: (change >= 0 ? "+" : "") + change.toFixed(2)
            color: {
              if (change > 0) return root.upColor
              if (change < 0) return root.downColor
              return root.neutralColor
            }
            pointSize: Style.fontSizeS
          }

          NText {
            text: ")"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
          }

          NText {
            visible: !parent.isLast
            text: " | "
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
          }
        }
      }
    }
  }
  }
  }
}