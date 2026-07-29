import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Services.UI
import qs.Widgets

DraggableDesktopWidget {
  id: root

  property var pluginApi: null

  readonly property string pluginWidgetId: "plugin:at-lazyvim-cs"
  readonly property var pluginMetadata: DesktopWidgetRegistry.widgetMetadata[pluginWidgetId] || ({})

  // Persisted per-instance settings, falling back to the manifest metadata.
  readonly property bool collapsed: widgetData && widgetData.collapsed !== undefined ? widgetData.collapsed : (pluginMetadata.collapsed !== undefined ? pluginMetadata.collapsed : true)
  readonly property int baseWidth: widgetData && widgetData.desktopWidth !== undefined ? widgetData.desktopWidth : (pluginMetadata.desktopWidth !== undefined ? pluginMetadata.desktopWidth : 340)
  readonly property int maxExpandedHeight: widgetData && widgetData.desktopMaxHeight !== undefined ? widgetData.desktopMaxHeight : (pluginMetadata.desktopMaxHeight !== undefined ? pluginMetadata.desktopMaxHeight : 560)
  readonly property bool showModes: widgetData && widgetData.showModes !== undefined ? widgetData.showModes : (pluginMetadata.showModes !== undefined ? pluginMetadata.showModes : false)

  // Plugin-wide color overrides, shared with the panel.
  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string keyColorLeaderOverride: cfg.keyColorLeader ?? defaults.keyColorLeader ?? ""
  readonly property string keyColorCtrlOverride: cfg.keyColorCtrl ?? defaults.keyColorCtrl ?? ""
  readonly property string keyColorShiftOverride: cfg.keyColorShift ?? defaults.keyColorShift ?? ""
  readonly property string keyColorAltOverride: cfg.keyColorAlt ?? defaults.keyColorAlt ?? ""
  readonly property string keyColorModeOverride: cfg.keyColorMode ?? defaults.keyColorMode ?? ""
  readonly property string keyColorDefaultOverride: cfg.keyColorDefault ?? defaults.keyColorDefault ?? ""
  readonly property string keyLabelColorOverride: cfg.keyLabelColor ?? defaults.keyLabelColor ?? ""
  readonly property string descriptionColorOverride: cfg.descriptionTextColor ?? defaults.descriptionTextColor ?? ""
  readonly property color descriptionTextColor: descriptionColorOverride !== "" ? descriptionColorOverride : Color.mOnSurface

  property int _dataVersion: pluginApi?.mainInstance?.cheatsheetDataVersion ?? 0
  readonly property var sections: {
    var _v = _dataVersion;
    var main = pluginApi?.mainInstance;
    if (!main)
      return [];
    return (root.collapsed ? main.compactData : main.cheatsheetData) || [];
  }

  readonly property real pad: Math.round(Style.marginM * widgetScale)
  readonly property real headerHeight: Math.round(26 * widgetScale)
  readonly property real rowHeight: Math.round(20 * widgetScale)
  readonly property real keyColumnWidth: Math.round(baseWidth * 0.46)

  defaultX: 60
  defaultY: 60

  implicitWidth: Math.round(baseWidth * widgetScale)
  implicitHeight: Math.round(Math.min(headerHeight + pad * 2 + Math.round(Style.marginS * widgetScale) + contentColumn.implicitHeight, maxExpandedHeight * widgetScale))
  width: implicitWidth
  height: implicitHeight

  function toggleCollapsed() {
    root.updateWidgetData({
                            "collapsed": !root.collapsed
                          });
  }

  function tokenizeKeys(keys) {
    var out = [];
    var pieces = (keys || "").split(" ");
    for (var i = 0; i < pieces.length; i++) {
      var p = pieces[i];
      if (!p)
        continue;
      out.push({
                 "text": p,
                 "separator": p === "+" || p === "/"
               });
    }
    return out;
  }

  function modeColor() {
    return keyColorModeOverride !== "" ? keyColorModeOverride : Color.mTertiary;
  }

  function modeTextColor() {
    return keyLabelColorOverride !== "" ? keyLabelColorOverride : Color.mOnSurface;
  }

  function getKeyColor(keyName) {
    if (keyName === "Space")
      return keyColorLeaderOverride !== "" ? keyColorLeaderOverride : Color.mPrimary;
    if (keyName === "Ctrl")
      return keyColorCtrlOverride !== "" ? keyColorCtrlOverride : Color.mSecondary;
    if (keyName === "Shift")
      return keyColorShiftOverride !== "" ? keyColorShiftOverride : Color.mTertiary;
    if (keyName === "Alt")
      return keyColorAltOverride !== "" ? keyColorAltOverride : Color.mTertiary;
    return keyColorDefaultOverride !== "" ? keyColorDefaultOverride : Color.mSurfaceVariant;
  }

  function getKeyTextColor(keyName) {
    if (keyName === "Space")
      return keyLabelColorOverride !== "" ? keyLabelColorOverride : Color.mOnPrimary;
    return keyLabelColorOverride !== "" ? keyLabelColorOverride : Color.mOnSurface;
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    spacing: Math.round(Style.marginS * root.widgetScale)

    // Header - click anywhere on it to collapse or expand
    Item {
      id: header
      Layout.fillWidth: true
      Layout.preferredHeight: root.headerHeight

      RowLayout {
        anchors.fill: parent
        spacing: Math.round(Style.marginXS * root.widgetScale)

        NIcon {
          icon: "keyboard"
          pointSize: Style.fontSizeM * root.widgetScale
          color: Color.mPrimary
        }

        NText {
          Layout.fillWidth: true
          text: root.pluginApi?.tr("desktopwidget.title") || "LazyVim"
          pointSize: Style.fontSizeS * root.widgetScale
          font.weight: Style.fontWeightBold
          color: Color.mPrimary
          elide: Text.ElideRight
        }

        NIcon {
          icon: root.collapsed ? "chevron-down" : "chevron-up"
          pointSize: Style.fontSizeM * root.widgetScale
          color: headerMouse.containsMouse ? Color.mPrimary : Color.mOnSurfaceVariant
        }
      }

      MouseArea {
        id: headerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: root.toggleCollapsed()
      }
    }

    // Sections - scrollable once the content outgrows the widget
    Flickable {
      id: flick
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      interactive: contentHeight > height
      contentWidth: width
      contentHeight: contentColumn.implicitHeight
      boundsBehavior: Flickable.StopAtBounds

      ColumnLayout {
        id: contentColumn
        width: flick.width
        spacing: Math.round(Style.marginS * root.widgetScale)

        Repeater {
          model: root.sections

          ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: Math.round(2 * root.widgetScale)

            NText {
              Layout.fillWidth: true
              Layout.topMargin: Math.round(Style.marginXS * root.widgetScale)
              text: modelData.title
              pointSize: Style.fontSizeXS * root.widgetScale
              font.weight: Style.fontWeightBold
              color: Color.mPrimary
              elide: Text.ElideRight
            }

            Repeater {
              model: modelData.binds || []

              RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: root.rowHeight
                spacing: Math.round(Style.marginXS * root.widgetScale)

                Flow {
                  Layout.preferredWidth: Math.round(root.keyColumnWidth * root.widgetScale)
                  Layout.alignment: Qt.AlignVCenter
                  spacing: Math.round(2 * root.widgetScale)

                  Repeater {
                    model: root.tokenizeKeys(modelData.keys)

                    Loader {
                      required property var modelData
                      property var tokenData: modelData
                      sourceComponent: modelData.separator ? keySeparatorComponent : keyBadgeComponent
                    }
                  }
                }

                NText {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  text: modelData.desc
                  pointSize: Style.fontSizeXS * root.widgetScale
                  color: root.descriptionTextColor
                  elide: Text.ElideRight
                }

                Rectangle {
                  visible: root.showModes
                  Layout.preferredWidth: Math.max(Math.round(22 * root.widgetScale), modeText.implicitWidth + Math.round(10 * root.widgetScale))
                  Layout.preferredHeight: Math.round(14 * root.widgetScale)
                  Layout.alignment: Qt.AlignVCenter
                  radius: height / 2
                  color: root.modeColor()

                  NText {
                    id: modeText
                    anchors.centerIn: parent
                    text: (modelData.modes || "").toUpperCase()
                    pointSize: Style.fontSizeXXS * root.widgetScale
                    font.weight: Style.fontWeightBold
                    color: root.modeTextColor()
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Component {
    id: keyBadgeComponent

    Rectangle {
      width: keyText.implicitWidth + Math.round(8 * root.widgetScale)
      height: Math.round(15 * root.widgetScale)
      radius: Math.round(3 * root.widgetScale)
      color: root.getKeyColor(tokenData.text)

      NText {
        id: keyText
        anchors.centerIn: parent
        text: tokenData.text
        family: Settings.data.ui.fontFixed
        pointSize: (tokenData.text.length > 8 ? Style.fontSizeXXS : Style.fontSizeXS) * root.widgetScale
        font.weight: Style.fontWeightBold
        color: root.getKeyTextColor(tokenData.text)
      }
    }
  }

  Component {
    id: keySeparatorComponent

    NText {
      text: tokenData.text
      pointSize: Style.fontSizeXS * root.widgetScale
      color: Color.mOnSurfaceVariant
    }
  }
}
