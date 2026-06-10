import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property int settingsWidth: cfg.windowWidth ?? defaults.windowWidth ?? 1280
  property int settingsHeight: cfg.windowHeight ?? defaults.windowHeight ?? 820
  property bool autoHeight: cfg.autoHeight ?? defaults.autoHeight ?? true
  property int columnCount: Math.max(1, Math.min(4, cfg.columnCount ?? defaults.columnCount ?? 3))
  property var panelOpenScreen: pluginApi?.panelOpenScreen
  property real maxScreenHeight: panelOpenScreen ? panelOpenScreen.height * 0.9 : 800

  property string searchText: ""
  property string modeFilter: "all"
  property int _dataVersion: pluginApi?.mainInstance?.cheatsheetDataVersion ?? 0
  property var categories: {
    var _v = _dataVersion;
    return pluginApi?.mainInstance?.cheatsheetData || [];
  }
  property var columnItems: []

  property real contentPreferredWidth: settingsWidth
  property real contentPreferredHeight: calculateDynamicHeight()
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: false
  readonly property bool panelAnchorHorizontalCenter: true
  readonly property bool panelAnchorVerticalCenter: true

  readonly property string keyColorLeaderOverride: cfg.keyColorLeader ?? defaults.keyColorLeader ?? ""
  readonly property string keyColorCtrlOverride: cfg.keyColorCtrl ?? defaults.keyColorCtrl ?? ""
  readonly property string keyColorShiftOverride: cfg.keyColorShift ?? defaults.keyColorShift ?? ""
  readonly property string keyColorAltOverride: cfg.keyColorAlt ?? defaults.keyColorAlt ?? ""
  readonly property string keyColorModeOverride: cfg.keyColorMode ?? defaults.keyColorMode ?? ""
  readonly property string keyColorDefaultOverride: cfg.keyColorDefault ?? defaults.keyColorDefault ?? ""
  readonly property string keyLabelColorOverride: cfg.keyLabelColor ?? defaults.keyLabelColor ?? ""
  readonly property string descriptionColorOverride: cfg.descriptionTextColor ?? defaults.descriptionTextColor ?? ""
  readonly property color keyLabelColor: keyLabelColorOverride !== "" ? keyLabelColorOverride : Color.mOnPrimary
  readonly property color descriptionTextColor: descriptionColorOverride !== "" ? descriptionColorOverride : Color.mOnSurface

  anchors.fill: parent

  Timer {
    id: columnUpdateDebounce
    interval: 80
    repeat: false
    onTriggered: updateColumnItemsNow()
  }

  Component.onCompleted: {
    updateColumnItemsNow();
    contentPreferredHeight = calculateDynamicHeight();
  }

  Component.onDestruction: columnUpdateDebounce.stop()

  onCategoriesChanged: {
    updateColumnItems();
    contentPreferredHeight = calculateDynamicHeight();
  }

  onColumnCountChanged: {
    updateColumnItems();
    contentPreferredHeight = calculateDynamicHeight();
  }

  onPanelOpenScreenChanged: {
    contentPreferredHeight = calculateDynamicHeight();
    if (searchInput) searchInput.inputItem.forceActiveFocus();
  }

  onMaxScreenHeightChanged: contentPreferredHeight = calculateDynamicHeight()

  function updateColumnItems() {
    columnUpdateDebounce.restart();
  }

  function updateColumnItemsNow() {
    var assignments = distributeCategories();
    var items = [];
    for (var i = 0; i < columnCount; i++) {
      items.push(buildColumnItems(assignments[i] || []));
    }
    columnItems = items;
  }

  function categoryVisibleBindCount(cat) {
    var count = 0;
    for (var i = 0; i < cat.binds.length; i++) {
      if (bindMatches(cat, cat.binds[i])) count++;
    }
    return count;
  }

  function bindMatches(cat, bnd) {
    var paddedModes = " " + bnd.modes + " ";
    var modeMatches = modeFilter === "all" ||
                      paddedModes.indexOf(" " + modeFilter + " ") !== -1 ||
                      (modeFilter === "x" && paddedModes.indexOf(" v ") !== -1);
    if (!modeMatches) {
      return false;
    }

    var term = searchText.toLowerCase().trim();
    if (!term) return true;

    return (cat.title || "").toLowerCase().indexOf(term) !== -1 ||
           (bnd.keys || "").toLowerCase().indexOf(term) !== -1 ||
           (bnd.desc || "").toLowerCase().indexOf(term) !== -1 ||
           (bnd.modes || "").toLowerCase().indexOf(term) !== -1;
  }

  function calculateDynamicHeight() {
    if (!autoHeight && settingsHeight > 0) {
      return Math.min(settingsHeight, maxScreenHeight);
    }

    if (!categories || categories.length === 0) return Math.min(360, maxScreenHeight);

    var assignments = distributeCategories();
    var maxColumnHeight = 0;

    for (var col = 0; col < columnCount; col++) {
      var colHeight = 0;
      var catIndices = assignments[col] || [];
      for (var i = 0; i < catIndices.length; i++) {
        var cat = categories[catIndices[i]];
        if (!cat) continue;
        var visibleCount = categoryVisibleBindCount(cat);
        if (visibleCount === 0) continue;
        colHeight += 28 + visibleCount * 24 + 8;
      }
      if (colHeight > maxColumnHeight) maxColumnHeight = colHeight;
    }

    return Math.max(340, Math.min(58 + maxColumnHeight + 34, maxScreenHeight));
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: Color.mSurface
    radius: Style.radiusL
    clip: true

    Rectangle {
      id: header
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 52
      color: Color.mSurfaceVariant
      radius: Style.radiusL

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.marginM
        anchors.rightMargin: Style.marginM
        spacing: Style.marginS

        NIcon {
          icon: "keyboard"
          pointSize: Style.fontSizeM
          color: Color.mPrimary
        }

        NText {
          text: pluginApi?.tr("panel.title") || "LazyVim Cheatsheet"
          font.pointSize: Style.fontSizeM
          font.weight: Font.Bold
          color: Color.mPrimary
        }

        NTextInput {
          id: searchInput
          Layout.fillWidth: true
          placeholderText: pluginApi?.tr("panel.search-placeholder") || "Search shortcuts..."
          text: root.searchText

          onTextChanged: {
            root.searchText = text;
            root.updateColumnItems();
            root.contentPreferredHeight = root.calculateDynamicHeight();
          }
        }

        Repeater {
          model: [
            { label: "All", mode: "all" },
            { label: "N", mode: "n" },
            { label: "I", mode: "i" },
            { label: "V", mode: "x" },
            { label: "T", mode: "t" }
          ]

          Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 28
            radius: 4
            color: root.modeFilter === modelData.mode ? root.modeColor() : Color.mSurface
            border.width: 1
            border.color: root.modeFilter === modelData.mode ? root.modeColor() : Color.mOutline

            NText {
              anchors.centerIn: parent
              text: modelData.label
              font.pointSize: Style.fontSizeXS
              font.weight: Font.Bold
              color: root.modeFilter === modelData.mode ? root.modeTextColor() : Color.mOnSurfaceVariant
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.modeFilter = modelData.mode;
                root.updateColumnItems();
                root.contentPreferredHeight = root.calculateDynamicHeight();
              }
            }
          }
        }

        NIconButton {
          icon: "settings"
          onClicked: {
            var screen = pluginApi?.panelOpenScreen;
            if (screen && pluginApi?.manifest) {
              pluginApi.closePanel(screen);
              BarService.openPluginSettings(screen, pluginApi.manifest);
            }
          }
        }
      }
    }

    NScrollView {
      id: scrollView
      anchors.top: header.bottom
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      clip: true
      leftPadding: 32
      rightPadding: 18
      topPadding: 16
      bottomPadding: 16

      RowLayout {
        width: scrollView.availableWidth - Style.marginS
        spacing: Style.marginL

        Repeater {
          model: root.columnItems.length

          ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 2

            property var colItems: root.columnItems[index] || []

            Repeater {
              model: colItems

              Loader {
                Layout.fillWidth: true
                sourceComponent: modelData.type === "header" ? headerComponent :
                                 modelData.type === "spacer" ? spacerComponent : bindComponent
                property var itemData: modelData
              }
            }
          }
        }
      }
    }
  }

  Component {
    id: headerComponent

    NText {
      Layout.fillWidth: true
      Layout.topMargin: Style.marginM
      Layout.bottomMargin: 4
      text: itemData.title
      font.pointSize: Style.fontSizeM
      font.weight: Font.Bold
      color: Color.mPrimary
    }
  }

  Component {
    id: spacerComponent

    Item {
      height: 8
      Layout.fillWidth: true
    }
  }

  Component {
    id: bindComponent

    RowLayout {
      spacing: Style.marginS
      height: 23
      Layout.bottomMargin: 1

      Flow {
        Layout.preferredWidth: 185
        Layout.alignment: Qt.AlignVCenter
        spacing: 3

        Repeater {
          model: root.tokenizeKeys(itemData.keys)

          Loader {
            sourceComponent: modelData.separator ? keySeparatorComponent : keyBadgeComponent
            property var tokenData: modelData
          }
        }
      }

      NText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        text: itemData.desc
        font.pointSize: Style.fontSizeXS
        color: root.descriptionTextColor
        elide: Text.ElideRight
      }

      Rectangle {
        Layout.preferredWidth: Math.max(26, modeText.implicitWidth + 12)
        Layout.preferredHeight: 18
        Layout.alignment: Qt.AlignVCenter
        radius: 9
        color: root.modeColor()

        NText {
          id: modeText
          anchors.centerIn: parent
          text: itemData.modes.toUpperCase()
          font.pointSize: 7
          font.weight: Font.Bold
          color: root.modeTextColor()
        }
      }
    }
  }

  Component {
    id: keyBadgeComponent

    Rectangle {
      width: keyText.implicitWidth + 10
      height: 18
      radius: 3
      color: root.getKeyColor(tokenData.text)

      NText {
        id: keyText
        anchors.centerIn: parent
        text: tokenData.text
        font.pointSize: tokenData.text.length > 10 ? 7 : 8
        font.weight: Font.Bold
        color: root.getKeyTextColor(tokenData.text)
      }
    }
  }

  Component {
    id: keySeparatorComponent

    NText {
      text: tokenData.text
      font.pointSize: Style.fontSizeXS
      color: Color.mOnSurfaceVariant
    }
  }

  function buildColumnItems(categoryIndices) {
    var result = [];
    for (var i = 0; i < categoryIndices.length; i++) {
      var cat = categories[categoryIndices[i]];
      if (!cat) continue;

      var binds = [];
      for (var j = 0; j < cat.binds.length; j++) {
        if (bindMatches(cat, cat.binds[j])) {
          binds.push(cat.binds[j]);
        }
      }

      if (binds.length === 0) continue;

      result.push({ type: "header", title: cat.title });
      for (var k = 0; k < binds.length; k++) {
        result.push({
          type: "bind",
          keys: binds[k].keys,
          desc: binds[k].desc,
          modes: binds[k].modes || "n"
        });
      }
      if (i < categoryIndices.length - 1) result.push({ type: "spacer" });
    }
    return result;
  }

  function distributeCategories() {
    var numCols = columnCount;
    var catData = [];

    for (var i = 0; i < categories.length; i++) {
      var visibleCount = categoryVisibleBindCount(categories[i]);
      if (visibleCount > 0) {
        catData.push({ index: i, weight: visibleCount + 2 });
      }
    }

    catData.sort(function(a, b) { return b.weight - a.weight; });

    var columns = [];
    var columnWeights = [];
    for (var c = 0; c < numCols; c++) {
      columns.push([]);
      columnWeights.push(0);
    }

    for (var j = 0; j < catData.length; j++) {
      var minCol = 0;
      for (var col = 1; col < numCols; col++) {
        if (columnWeights[col] < columnWeights[minCol]) minCol = col;
      }
      columns[minCol].push(catData[j].index);
      columnWeights[minCol] += catData[j].weight;
    }

    for (var sortCol = 0; sortCol < numCols; sortCol++) {
      columns[sortCol].sort(function(a, b) { return a - b; });
    }

    return columns;
  }

  function tokenizeKeys(keys) {
    var out = [];
    var pieces = (keys || "").split(" ");

    for (var i = 0; i < pieces.length; i++) {
      var p = pieces[i];
      if (!p) continue;
      if (p === "+" || p === "/") {
        out.push({ text: p, separator: true });
      } else {
        out.push({ text: p, separator: false });
      }
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
    if (keyName === "Space") return keyColorLeaderOverride !== "" ? keyColorLeaderOverride : Color.mPrimary;
    if (keyName === "Ctrl") return keyColorCtrlOverride !== "" ? keyColorCtrlOverride : Color.mSecondary;
    if (keyName === "Shift") return keyColorShiftOverride !== "" ? keyColorShiftOverride : Color.mTertiary;
    if (keyName === "Alt") return keyColorAltOverride !== "" ? keyColorAltOverride : Color.mTertiary;
    if (keyName === "Esc" || keyName === "Tab") return Color.mSurfaceVariant;
    return keyColorDefaultOverride !== "" ? keyColorDefaultOverride : Color.mSurfaceVariant;
  }

  function getKeyTextColor(keyName) {
    if (keyName === "Space") return keyLabelColorOverride !== "" ? keyLabelColorOverride : Color.mOnPrimary;
    if (keyName === "Ctrl" || keyName === "Shift" || keyName === "Alt") return keyLabelColorOverride !== "" ? keyLabelColorOverride : Color.mOnSurface;
    return keyLabelColorOverride !== "" ? keyLabelColorOverride : Color.mOnSurface;
  }
}
