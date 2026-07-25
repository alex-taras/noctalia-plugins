import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property var defaultSettings: pluginApi?.manifest?.metadata?.defaultSettings || {}

  property string credentialsPath: "~/.claude/.credentials.json"
  property int refreshIntervalMinutes: 5
  property int warnThreshold: 70
  property int dangerThreshold: 90
  property bool showExtraUsage: true

  property string settingsBuffer: ""
  property var i18n: ({})
  property string i18nBuffer: ""

  spacing: Style.marginL

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

  Process {
    command: ["cat", Qt.resolvedUrl("settings.json").toString().replace("file://", "")]
    running: true

    stdout: SplitParser {
      onRead: data => root.settingsBuffer += data
    }

    onExited: () => {
      try {
        const s = JSON.parse(root.settingsBuffer)
        root.credentialsPath = s.credentialsPath || root.defaultSettings.credentialsPath || "~/.claude/.credentials.json"
        root.refreshIntervalMinutes = s.refreshIntervalMinutes || root.defaultSettings.refreshIntervalMinutes || 5
        root.warnThreshold = s.warnThreshold || root.defaultSettings.warnThreshold || 70
        root.dangerThreshold = s.dangerThreshold || root.defaultSettings.dangerThreshold || 90
        root.showExtraUsage = s.showExtraUsage !== undefined ? s.showExtraUsage : (root.defaultSettings.showExtraUsage !== undefined ? root.defaultSettings.showExtraUsage : true)
      } catch (e) {
        Logger.e("AiUsage", "Failed to parse settings in UI: " + e)
      }
    }
  }

  NText {
    text: root.i18n?.settings?.disclaimer || "Uses Claude Code's own OAuth session (from ~/.claude/.credentials.json) against an undocumented Anthropic endpoint. May break without notice."
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    color: Color.mOnSurfaceVariant
    pointSize: Style.fontSizeS
  }

  NTextInput {
    Layout.fillWidth: true
    label: root.i18n?.settings?.credentialsPath?.label || "Credentials File Path"
    description: root.i18n?.settings?.credentialsPath?.description || "Path to Claude Code's credentials.json"
    placeholderText: "~/.claude/.credentials.json"
    text: root.credentialsPath
    onTextChanged: root.credentialsPath = text
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
  }

  ColumnLayout {
    spacing: Style.marginM

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NLabel {
        label: root.i18n?.settings?.refreshInterval?.label || "Refresh Interval"
        description: root.i18n?.settings?.refreshInterval?.description || "How often to poll usage, in minutes"
      }

      NText {
        text: root.refreshIntervalMinutes + " min"
        color: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mOnPrimary
      }
    }

    NSlider {
      Layout.fillWidth: true
      from: 1
      to: 30
      value: root.refreshIntervalMinutes
      stepSize: 1
      onValueChanged: root.refreshIntervalMinutes = value
    }
  }

  ColumnLayout {
    spacing: Style.marginM

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NLabel {
        label: root.i18n?.settings?.warnThreshold?.label || "Warn Threshold"
        description: root.i18n?.settings?.warnThreshold?.description || "Utilization % at which the widget turns yellow"
      }

      NText {
        text: root.warnThreshold + "%"
        color: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mOnPrimary
      }
    }

    NSlider {
      Layout.fillWidth: true
      from: 10
      to: 95
      value: root.warnThreshold
      stepSize: 5
      onValueChanged: root.warnThreshold = value
    }
  }

  ColumnLayout {
    spacing: Style.marginM

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NLabel {
        label: root.i18n?.settings?.dangerThreshold?.label || "Danger Threshold"
        description: root.i18n?.settings?.dangerThreshold?.description || "Utilization % at which the widget turns red"
      }

      NText {
        text: root.dangerThreshold + "%"
        color: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mOnPrimary
      }
    }

    NSlider {
      Layout.fillWidth: true
      from: 10
      to: 100
      value: root.dangerThreshold
      stepSize: 5
      onValueChanged: root.dangerThreshold = value
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
  }

  NToggle {
    label: root.i18n?.settings?.showExtraUsage?.label || "Show Pay-as-you-go Credits"
    description: root.i18n?.settings?.showExtraUsage?.description || "Also display extra usage credit utilization if enabled on your account"
    checked: root.showExtraUsage
    onToggled: function (checked) {
      root.showExtraUsage = checked
    }
  }

  function saveSettings() {
    const settingsObj = {
      credentialsPath: root.credentialsPath,
      refreshIntervalMinutes: root.refreshIntervalMinutes,
      warnThreshold: root.warnThreshold,
      dangerThreshold: root.dangerThreshold,
      showExtraUsage: root.showExtraUsage
    }

    const json = JSON.stringify(settingsObj, null, 2)
    const settingsPath = Qt.resolvedUrl("settings.json").toString().replace("file://", "")
    const cmd = "echo '" + json + "' > " + settingsPath

    const proc = Qt.createQmlObject(`
      import Quickshell.Io
      Process {
        command: ["bash", "-c", "${cmd.replace(/"/g, '\\"')}"]
        running: true
      }
    `, root)

    proc.exited.connect((code) => {
      if (code === 0) {
        if (pluginApi && pluginApi.mainInstance) {
          pluginApi.mainInstance.loadSettings()
        }
        if (pluginApi) {
          pluginApi.closePanel(root.screen)
        }
      } else {
        Logger.e("AiUsage", "Failed to save settings")
      }
      proc.destroy()
    })
  }
}
