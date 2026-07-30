import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property int editWindowWidth: cfg.windowWidth ?? defaults.windowWidth ?? 1280
  property int editWindowHeight: cfg.windowHeight ?? defaults.windowHeight ?? 820
  property bool editAutoHeight: cfg.autoHeight ?? defaults.autoHeight ?? true
  property int editColumnCount: cfg.columnCount ?? defaults.columnCount ?? 3

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.title") || "LazyVim Cheatsheet Settings"
    font.pointSize: Style.fontSizeL
    font.weight: Font.Bold
    color: Color.mOnSurface
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.description") || "Configure the LazyVim cheatsheet panel."
    font.pointSize: Style.fontSizeS
    color: Color.mOnSurfaceVariant
    wrapMode: Text.WordWrap
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: contentLayout.implicitHeight + Style.marginL * 2
    radius: Style.radiusM
    color: Color.mSurfaceVariant

    ColumnLayout {
      id: contentLayout
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("settings.layout") || "Layout"
        font.pointSize: Style.fontSizeM
        font.weight: Font.Bold
        color: Color.mOnSurface
      }

      // One control per row: NSpinBox and NToggle each carry their own label and
      // already set Layout.fillWidth, so packing several into one row starves them.
      NSpinBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.width") || "Width"
        from: 600
        to: 2200
        stepSize: 20
        suffix: "px"
        value: root.editWindowWidth
        onValueChanged: root.editWindowWidth = value
      }

      NToggle {
        Layout.fillWidth: true
        checked: root.editAutoHeight
        label: pluginApi?.tr("settings.auto-height") || "Auto height"
        onToggled: function (checked) {
          root.editAutoHeight = checked;
        }
      }

      NSpinBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.height") || "Height"
        from: 300
        to: 1600
        stepSize: 20
        suffix: "px"
        value: root.editWindowHeight
        enabled: !root.editAutoHeight
        onValueChanged: root.editWindowHeight = value
      }

      NSpinBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.columns") || "Columns"
        from: 1
        to: 4
        value: root.editColumnCount
        onValueChanged: root.editColumnCount = value
      }
    }
  }

  Item { Layout.fillHeight: true }

  function saveSettings() {
    if (!pluginApi) return;
    // Clamp rather than trust the edit values: a spinbox that is bound before
    // pluginApi resolves can report its own 0 default and poison the settings.
    pluginApi.pluginSettings.windowWidth = Math.max(600, Math.min(2200, root.editWindowWidth || 1280));
    pluginApi.pluginSettings.windowHeight = Math.max(300, Math.min(1600, root.editWindowHeight || 820));
    pluginApi.pluginSettings.autoHeight = root.editAutoHeight;
    pluginApi.pluginSettings.columnCount = Math.max(1, Math.min(4, root.editColumnCount || 3));
    pluginApi.saveSettings();
    pluginApi.mainInstance?.refresh();
  }
}
