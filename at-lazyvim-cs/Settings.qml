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

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NText {
          text: pluginApi?.tr("settings.width") || "Width"
          color: Color.mOnSurface
        }

        NSpinBox {
          from: 600
          to: 2200
          stepSize: 20
          value: root.editWindowWidth
          onValueChanged: root.editWindowWidth = value
        }

        NText {
          text: pluginApi?.tr("settings.height") || "Height"
          color: Color.mOnSurface
        }

        NSpinBox {
          from: 300
          to: 1600
          stepSize: 20
          value: root.editWindowHeight
          enabled: !root.editAutoHeight
          onValueChanged: root.editWindowHeight = value
        }

        NToggle {
          checked: root.editAutoHeight
          label: pluginApi?.tr("settings.auto-height") || "Auto height"
          onToggled: function(checked) {
            root.editAutoHeight = checked;
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NText {
          text: pluginApi?.tr("settings.columns") || "Columns"
          color: Color.mOnSurface
        }

        NSpinBox {
          from: 1
          to: 4
          value: root.editColumnCount
          onValueChanged: root.editColumnCount = value
        }

        Item { Layout.fillWidth: true }
      }
    }
  }

  Item { Layout.fillHeight: true }

  function saveSettings() {
    if (!pluginApi) return;
    pluginApi.pluginSettings.windowWidth = root.editWindowWidth;
    pluginApi.pluginSettings.windowHeight = root.editWindowHeight;
    pluginApi.pluginSettings.autoHeight = root.editAutoHeight;
    pluginApi.pluginSettings.columnCount = root.editColumnCount;
    pluginApi.saveSettings();
    pluginApi.mainInstance?.refresh();
  }
}
