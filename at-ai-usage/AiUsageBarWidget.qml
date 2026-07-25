import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import "." as Local

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  property var settings: ({})
  property int warnThreshold: 70
  property int dangerThreshold: 90

  property var i18n: ({})
  property string i18nBuffer: ""
  property string settingsBuffer: ""

  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name || "")
  readonly property color okColor: Color.mOnSurface
  readonly property color warnColor: "#facc15"
  readonly property color dangerColor: Color.mError

  implicitWidth: container.implicitWidth
  implicitHeight: Style.barHeight

  function colorFor(pct) {
    if (pct >= dangerThreshold) return dangerColor
    if (pct >= warnThreshold) return warnColor
    return okColor
  }

  Process {
    id: i18nLoader
    command: ["cat", Qt.resolvedUrl("i18n/" + (Settings.data.locale || "en") + ".json").toString().replace("file://", "")]
    running: true

    stdout: SplitParser {
      onRead: data => root.i18nBuffer += data
    }

    onExited: () => {
      try {
        root.i18n = JSON.parse(root.i18nBuffer)
      } catch (e) {
        i18nFallback.running = true
      }
    }
  }

  Process {
    id: i18nFallback
    command: ["cat", Qt.resolvedUrl("i18n/en.json").toString().replace("file://", "")]

    stdout: SplitParser {
      onRead: data => root.i18nBuffer += data
    }

    onExited: () => {
      try {
        root.i18n = JSON.parse(root.i18nBuffer)
      } catch (e) {}
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: settingsLoader.running = true
  }

  Process {
    id: settingsLoader
    command: ["cat", Qt.resolvedUrl("settings.json").toString().replace("file://", "")]

    property string tempBuffer: ""

    stdout: SplitParser {
      onRead: data => settingsLoader.tempBuffer += data
    }

    onExited: () => {
      try {
        const newSettings = JSON.parse(tempBuffer)
        tempBuffer = ""

        const changed = JSON.stringify(newSettings) !== JSON.stringify(root.settings)
        if (changed) {
          root.settings = newSettings
          root.warnThreshold = root.settings.warnThreshold || 70
          root.dangerThreshold = root.settings.dangerThreshold || 90
        }
      } catch (e) {
        tempBuffer = ""
      }
    }
  }

  Rectangle {
    id: container
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    implicitWidth: contentRow.implicitWidth + Style.marginM * 2
    height: capsuleHeight

    color: Style.capsuleColor
    radius: Style.radiusM

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: Local.AiUsageService.fetchUsage()
    }

    RowLayout {
      id: contentRow
      anchors.centerIn: parent
      spacing: Style.marginXS

      NText {
        visible: Local.AiUsageService.error !== ""
        text: root.i18n?.widget?.error || "AI usage unavailable"
        color: root.dangerColor
        pointSize: Style.fontSizeS
      }

      RowLayout {
        visible: Local.AiUsageService.error === ""
        spacing: Style.marginXS

        NText {
          text: root.i18n?.widget?.fiveHourLabel || "5h"
          color: Color.mOnSurfaceVariant
          pointSize: Style.fontSizeS
        }

        NText {
          text: Math.round(Local.AiUsageService.fiveHourUtil) + "%"
          color: root.colorFor(Local.AiUsageService.fiveHourUtil)
          pointSize: Style.fontSizeS
        }

        NText {
          text: "·"
          color: Color.mOnSurfaceVariant
          pointSize: Style.fontSizeS
        }

        NText {
          text: root.i18n?.widget?.sevenDayLabel || "7d"
          color: Color.mOnSurfaceVariant
          pointSize: Style.fontSizeS
        }

        NText {
          text: Math.round(Local.AiUsageService.sevenDayUtil) + "%"
          color: root.colorFor(Local.AiUsageService.sevenDayUtil)
          pointSize: Style.fontSizeS
        }

        NText {
          visible: root.settings.showExtraUsage !== false && Local.AiUsageService.extraUsageEnabled
          text: "·"
          color: Color.mOnSurfaceVariant
          pointSize: Style.fontSizeS
        }

        NText {
          visible: root.settings.showExtraUsage !== false && Local.AiUsageService.extraUsageEnabled
          text: (root.i18n?.widget?.extraLabel || "credits") + " " + Math.round(Local.AiUsageService.extraUsageUtil) + "%"
          color: root.colorFor(Local.AiUsageService.extraUsageUtil)
          pointSize: Style.fontSizeS
        }
      }
    }
  }
}
