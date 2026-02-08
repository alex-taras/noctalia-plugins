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

  property string finnhubApiKey: ""
  property string symbolsText: ""
  property int maxWidth: 300
  property bool enableAutoscroll: true

  property string settingsBuffer: ""
  property var i18n: ({})
  property string i18nBuffer: ""

  spacing: Style.marginL

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
        Logger.e("Stonks", "Failed to load i18n, falling back to English: " + e)
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
        Logger.e("Stonks", "Failed to load English fallback: " + e)
      }
    }
  }

  // Load settings from settings.json
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
        root.finnhubApiKey = settings.finnhubApiKey || root.defaultSettings.finnhubApiKey || ""
        root.symbolsText = settings.symbols ? settings.symbols.join(",") : (root.defaultSettings.symbols ? root.defaultSettings.symbols.join(",") : "AAPL,TSLA,GOOG")
        root.maxWidth = settings.width || root.defaultSettings.width || 300
        root.enableAutoscroll = settings.autoscroll !== undefined ? settings.autoscroll : (root.defaultSettings.autoscroll !== undefined ? root.defaultSettings.autoscroll : true)
      } catch (e) {
        Logger.e("Stonks", "Failed to parse settings in UI: " + e)
      }
    }
  }

  // API Key
  NTextInput {
    Layout.fillWidth: true
    label: root.i18n?.settings?.apiKey?.label || "Finnhub API Key"
    description: root.i18n?.settings?.apiKey?.description || "Your API key from finnhub.io"
    placeholderText: root.i18n?.settings?.apiKey?.placeholder || "Enter your Finnhub API key"
    text: root.finnhubApiKey
    onTextChanged: root.finnhubApiKey = text
  }

  // Symbols
  NTextInput {
    Layout.fillWidth: true
    label: root.i18n?.settings?.symbols?.label || "Stock Symbols"
    description: root.i18n?.settings?.symbols?.description || "Comma-separated list of stock symbols with no spaces (e.g., AAPL,TSLA,GOOG)"
    placeholderText: root.defaultSettings.symbols ? root.defaultSettings.symbols.join(",") : "AAPL,TSLA,GOOG"
    text: root.symbolsText
    onTextChanged: {
      root.symbolsText = text
    }
  }

  NDivider {
    visible: true
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
  }

  // Width
  ColumnLayout {
    spacing: Style.marginM

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NLabel {
        label: root.i18n?.settings?.width?.label || "Minimum Widget Width"
        description: root.i18n?.settings?.width?.description || "Minimum width of the widget in pixels (content hugs up to this size)"
      }

      NText {
        text: root.maxWidth.toString() + " px"
        color: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mOnPrimary
      }
    }

    NSlider {
      Layout.fillWidth: true
      from: 100
      to: 800
      value: root.maxWidth
      stepSize: 50
      onValueChanged: {
        root.maxWidth = value
      }
    }
  }

  // Auto-scroll toggle
  NToggle {
    id: autoscrollSwitch
    label: root.i18n?.settings?.autoscroll?.label || "Auto-scroll"
    description: root.i18n?.settings?.autoscroll?.description || "Automatically scroll when content doesn't fit"
    checked: root.enableAutoscroll
    onToggled: function (checked) {
      root.enableAutoscroll = checked
    }
  }

  NDivider {
    visible: true
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
  }

  // Information
  NLabel {
    label: root.i18n?.settings?.current?.label || "Current Settings"
  }

  ColumnLayout {
    NText {
      text: (root.i18n?.settings?.current?.symbols || "Symbols") + ": " + root.symbolsText
      color: Settings.data.colorSchemes.darkMode ? Color.mSecondary : Color.mOnSecondary
    }
    NText {
      text: (root.i18n?.settings?.current?.width || "Width") + ": " + root.maxWidth + "px"
      color: Settings.data.colorSchemes.darkMode ? Color.mSecondary : Color.mOnSecondary
    }
    NText {
      text: (root.i18n?.settings?.current?.autoscroll || "Auto-scroll") + ": " + (root.enableAutoscroll ? (root.i18n?.settings?.current?.enabled || "Enabled") : (root.i18n?.settings?.current?.disabled || "Disabled"))
      color: Settings.data.colorSchemes.darkMode ? Color.mSecondary : Color.mOnSecondary
    }
  }

  function saveSettings() {
    const symbolsArray = root.symbolsText.split(",").map(s => s.trim()).filter(s => s.length > 0)

    const settingsObj = {
      finnhubApiKey: root.finnhubApiKey,
      symbols: symbolsArray,
      width: root.maxWidth,
      autoscroll: root.enableAutoscroll
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
        // Trigger plugin reload by calling the service
        if (pluginApi && pluginApi.mainInstance) {
          pluginApi.mainInstance.loadSettings()
        }

        if (pluginApi) {
          pluginApi.closePanel(root.screen)
        }
      } else {
        Logger.e("Stonks", "Failed to save settings")
      }
      proc.destroy()
    })
  }
}
