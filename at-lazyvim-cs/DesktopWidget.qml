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
  readonly property int collapsedWidth: widgetData && widgetData.desktopWidth !== undefined ? widgetData.desktopWidth : (pluginMetadata.desktopWidth !== undefined ? pluginMetadata.desktopWidth : 380)
  readonly property int collapsedMaxHeight: widgetData && widgetData.desktopMaxHeight !== undefined ? widgetData.desktopMaxHeight : (pluginMetadata.desktopMaxHeight !== undefined ? pluginMetadata.desktopMaxHeight : 560)
  readonly property bool showModes: widgetData && widgetData.showModes !== undefined ? widgetData.showModes : (pluginMetadata.showModes !== undefined ? pluginMetadata.showModes : false)

  // Expanded matches the bar widget's panel: same width setting, and the height
  // the panel computes for its own content. Clamped so it stays on screen.
  readonly property int panelWidth: (cfg.windowWidth > 0 ? cfg.windowWidth : (defaults.windowWidth > 0 ? defaults.windowWidth : 1280))
  // Clamps are expressed in unscaled units so they survive widgetScale: the final
  // on-screen size is (value * widgetScale), so divide the screen budget by the
  // scale before comparing. Without this a scaled-up widget overflows the monitor.
  readonly property real sizeBudget: widgetScale > 0 ? widgetScale : 1
  readonly property int maxExpandedWidth: screen ? Math.round(screen.width * 0.94 / sizeBudget) : 1280
  readonly property int maxExpandedHeight: screen ? Math.round(screen.height * 0.94 / sizeBudget) : 820
  readonly property int effectiveExpandedWidth: Math.max(320, Math.min(panelWidth, maxExpandedWidth))
  readonly property int effectiveExpandedHeight: Math.max(240, Math.min(panelLoader.item ? panelLoader.item.contentPreferredHeight : 400, maxExpandedHeight))

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
    return pluginApi?.mainInstance?.compactData || [];
  }

  readonly property real pad: Math.round(Style.marginM * widgetScale)
  readonly property real headerHeight: Math.round(26 * widgetScale)
  readonly property real rowHeight: Math.round(20 * widgetScale)
  // Matches the panel's key column so the longest chord fits without wrapping.
  readonly property real keyColumnWidth: 168

  defaultX: 60
  defaultY: 60

  implicitWidth: Math.round(Math.min(collapsed ? collapsedWidth : effectiveExpandedWidth, maxExpandedWidth) * widgetScale)
  implicitHeight: {
    if (!collapsed)
      return Math.round(effectiveExpandedHeight * widgetScale);
    var natural = headerHeight + pad * 2 + Math.round(Style.marginS * widgetScale) + collapsedColumn.implicitHeight;
    return Math.round(Math.min(natural, collapsedMaxHeight * widgetScale, maxExpandedHeight * widgetScale));
  }
  width: implicitWidth
  height: implicitHeight

  function toggleCollapsed() {
    if (root.collapsed) {
      // Expanding: remember where the strip sat, then center the wide panel.
      // pendingCenter is persisted because updating the widget data rebuilds
      // this item, so an in-memory flag would not survive the round trip.
      root.updateWidgetData({
                              "collapsed": false,
                              "pendingCenter": true,
                              "collapsedX": Math.round(root.x),
                              "collapsedY": Math.round(root.y)
                            });
      return;
    }

    var props = {
      "collapsed": true,
      "pendingCenter": false
    };
    if (widgetData && widgetData.collapsedX !== undefined) {
      props.x = widgetData.collapsedX;
      props.y = widgetData.collapsedY;
    }
    root.updateWidgetData(props);
  }

  // Re-center the expanded panel whenever its size settles - on expand, and again
  // after the width/height settings change.
  function centerOnScreen() {
    if (root.collapsed || !root.screen || !widgetData) {
      return;
    }
    if (root.width <= 0 || root.height <= 0) {
      return;
    }

    var targetX = Math.max(0, Math.round((root.screen.width - root.width) / 2));
    var targetY = Math.max(0, Math.round((root.screen.height - root.height) / 2));

    // Writing widget data rebuilds this item and re-runs the timer, so bail out
    // once we are already centered - otherwise the rebuild loops forever.
    if (widgetData.x === targetX && widgetData.y === targetY && !widgetData.pendingCenter) {
      return;
    }

    root.updateWidgetData({
                            "x": targetX,
                            "y": targetY,
                            "pendingCenter": false
                          });
  }

  Timer {
    id: centerDebounce
    interval: 120
    repeat: false
    // Fires on creation too, which is when a freshly expanded instance appears.
    running: !root.collapsed
    onTriggered: root.centerOnScreen()
  }

  // A settings change resizes the embedded panel without recreating the widget,
  // so watch the resolved size directly rather than relying on expand alone.
  onEffectiveExpandedWidthChanged: if (!root.collapsed)
                                     centerDebounce.restart()
  onEffectiveExpandedHeightChanged: if (!root.collapsed)
                                      centerDebounce.restart()

  // Note: no Component.onCompleted here - DraggableDesktopWidget uses it to
  // initialize widgetScale, and a handler in this file would replace it.
  onHeightChanged: if (!root.collapsed)
                     centerDebounce.restart()
  onWidthChanged: if (!root.collapsed)
                    centerDebounce.restart()

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

  // Expanded: reuse the bar panel, which already does multi-column layout,
  // search and mode filtering. It fills the widget and draws its own surface.
  Loader {
    id: panelLoader
    anchors.fill: parent
    active: !root.collapsed
    asynchronous: true
    source: active ? "Panel.qml" : ""
  }

  Binding {
    target: panelLoader.item
    property: "pluginApi"
    value: root.pluginApi
    when: panelLoader.item !== null
  }

  // The panel derives these from the screen the bar opened it on, which is unset
  // on the desktop - point them at the monitor the widget lives on instead, so
  // its height clamp and its settings button both work here.
  Binding {
    target: panelLoader.item
    property: "hostScreen"
    value: root.screen
    when: panelLoader.item !== null
  }

  Binding {
    target: panelLoader.item
    property: "maxScreenHeight"
    value: root.maxExpandedHeight
    when: panelLoader.item !== null && root.screen !== null
  }

  // Collapse control for the expanded state, pinned clear of the panel's own
  // header controls at the bottom-right corner.
  NIconButton {
    visible: !root.collapsed && panelLoader.status === Loader.Ready
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Math.round(Style.marginS * root.widgetScale)
    baseSize: Math.round(Style.baseWidgetSize * 0.8 * root.widgetScale)
    icon: "chevron-up"
    tooltipText: root.pluginApi?.tr("desktopwidget.collapse") || "Show essentials only"
    z: 10
    onClicked: root.toggleCollapsed()
  }

  // Collapsed: the curated essentials, rendered compactly.
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    spacing: Math.round(Style.marginS * root.widgetScale)
    visible: root.collapsed

    // Header - click anywhere on it to expand
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
          icon: "chevron-down"
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
      contentHeight: collapsedColumn.implicitHeight
      boundsBehavior: Flickable.StopAtBounds

      ColumnLayout {
        id: collapsedColumn
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
                spacing: Math.round(Style.marginXXS * root.widgetScale)

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
