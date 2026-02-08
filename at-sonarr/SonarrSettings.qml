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

  property string sonarrHost: ""
  property string sonarrPort: ""
  property string apiKey: ""

  property string settingsBuffer: ""

  spacing: Style.marginL

  Process {
    command: ["cat", Qt.resolvedUrl("settings.json").toString().replace("file://", "")]
    running: true

    stdout: SplitParser {
      onRead: data => {
        root.settingsBuffer += data
      }
    }

    onExited: () => {
      try {
        const settings = JSON.parse(root.settingsBuffer)
        root.sonarrHost = settings.sonarrHost || root.defaultSettings.sonarrHost || ""
        root.sonarrPort = settings.sonarrPort || root.defaultSettings.sonarrPort || "8989"
        root.apiKey = settings.apiKey || root.defaultSettings.apiKey || ""
      } catch (e) {
        Logger.e("Sonarr", "Failed to parse settings in UI: " + e)
      }
    }
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Sonarr Host"
    description: "IP address or hostname of your Sonarr server"
    placeholderText: "192.168.1.137"
    text: root.sonarrHost
    onTextChanged: root.sonarrHost = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Sonarr Port"
    description: "Port number for your Sonarr server"
    placeholderText: "8989"
    text: root.sonarrPort
    onTextChanged: root.sonarrPort = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "API Key"
    description: "Your Sonarr API key (found in Settings > General)"
    placeholderText: "Enter your Sonarr API key"
    text: root.apiKey
    onTextChanged: root.apiKey = text
  }

  NDivider {
    visible: true
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
  }

  NLabel {
    label: "Current Settings"
  }

  ColumnLayout {
    NText {
      text: "URL: http://" + (root.sonarrHost || "not set") + ":" + (root.sonarrPort || "8989")
      color: Settings.data.colorSchemes.darkMode ? Color.mSecondary : Color.mOnSecondary
    }
    NText {
      text: "API Key: " + (root.apiKey ? "•".repeat(root.apiKey.length) : "not set")
      color: Settings.data.colorSchemes.darkMode ? Color.mSecondary : Color.mOnSecondary
    }
  }

  function saveSettings() {
    const settingsObj = {
      sonarrHost: root.sonarrHost,
      sonarrPort: root.sonarrPort,
      apiKey: root.apiKey
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
        Logger.e("Sonarr", "Failed to save settings")
      }
      proc.destroy()
    })
  }
}
