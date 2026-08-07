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

  property int settingsWidth: (cfg.windowWidth > 0 ? cfg.windowWidth : (defaults.windowWidth > 0 ? defaults.windowWidth : 1280))
  property int settingsHeight: (cfg.windowHeight > 0 ? cfg.windowHeight : (defaults.windowHeight > 0 ? defaults.windowHeight : 820))
  property bool autoHeight: cfg.autoHeight ?? defaults.autoHeight ?? true
  property int columnCount: Math.max(1, Math.min(4, cfg.columnCount ?? defaults.columnCount ?? 3))
  property var panelOpenScreen: pluginApi?.panelOpenScreen
  // Set when embedded outside the bar panel (desktop widget), where there is no
  // panelOpenScreen to fall back on.
  property var hostScreen: null
  readonly property bool embedded: hostScreen !== null
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
  // Wide enough for the longest chord ("Shift + h / Shift + l") without wrapping,
  // but no wider - the remainder goes to the description so it stops eliding.
  readonly property int keyColumnWidth: 168
  readonly property int rowHeight: 26
  readonly property int sectionHeaderHeight: 30
  readonly property int sectionPadding: 10
  readonly property int sectionGap: 10
  readonly property int headerHeight: 52

  anchors.fill: parent

  Timer {
    id: columnUpdateDebounce
    interval: 80
    repeat: false
    onTriggered: updatePanelLayout()
  }

  Component.onCompleted: {
    updatePanelLayout();
  }

  Component.onDestruction: columnUpdateDebounce.stop()

  onCategoriesChanged: {
    updateColumnItems();
  }

  onColumnCountChanged: {
    updateColumnItems();
  }

  onPanelOpenScreenChanged: {
    updatePanelLayout();
    if (searchInput) searchInput.inputItem.forceActiveFocus();
  }

  onPluginApiChanged: updatePanelLayout()
  onMaxScreenHeightChanged: updatePanelLayout()
  onSearchTextChanged: updatePanelLayout()
  onModeFilterChanged: updatePanelLayout()

  function updateColumnItems() {
    columnUpdateDebounce.restart();
  }

  function updatePanelLayout() {
    var assignments = distributeCategories();
    var items = [];
    for (var i = 0; i < columnCount; i++) {
      items.push(buildColumnItems(assignments[i] || []));
    }
    columnItems = items;
    contentPreferredHeight = calculateDynamicHeightForColumns(items);
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
        colHeight += sectionHeightForBindCount(visibleCount) + sectionGap;
      }
      if (colHeight > maxColumnHeight) maxColumnHeight = colHeight;
    }

    return Math.max(340, Math.min(headerHeight + maxColumnHeight + 34, maxScreenHeight));
  }

  function calculateDynamicHeightForColumns(cols) {
    if (!autoHeight && settingsHeight > 0) {
      return Math.min(settingsHeight, maxScreenHeight);
    }

    if (!cols || cols.length === 0) return Math.min(360, maxScreenHeight);

    var maxColumnHeight = 0;
    for (var col = 0; col < cols.length; col++) {
      var colHeight = 0;
      var sections = cols[col] || [];
      for (var i = 0; i < sections.length; i++) {
        var binds = sections[i].binds || [];
        colHeight += sectionHeightForBindCount(binds.length) + sectionGap;
      }
      if (colHeight > maxColumnHeight) maxColumnHeight = colHeight;
    }

    return Math.max(340, Math.min(headerHeight + maxColumnHeight + 36, maxScreenHeight));
  }

  function sectionHeightForBindCount(bindCount) {
    return sectionHeaderHeight +
           (bindCount * rowHeight) +
           (Math.max(0, bindCount - 1) * 4) +
           (sectionPadding * 2);
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
      height: root.headerHeight
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
              }
            }
          }
        }

        NIconButton {
          icon: "settings"
          onClicked: {
            var screen = pluginApi?.panelOpenScreen || root.hostScreen;
            if (!screen || !pluginApi?.manifest) {
              return;
            }
            // Only the bar panel needs closing - the embedded copy stays put.
            if (pluginApi?.panelOpenScreen) {
              pluginApi.closePanel(screen);
            }
            BarService.openPluginSettings(screen, pluginApi.manifest);
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
      leftPadding: 20
      rightPadding: 14
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
            spacing: root.sectionGap

            property var colItems: root.columnItems[index] || []

            Repeater {
              model: colItems

              Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: root.sectionHeightForBindCount((modelData.binds || []).length)
                sourceComponent: sectionComponent
                property var sectionData: modelData
              }
            }
          }
        }
      }
    }
  }

  Component {
    id: sectionComponent

    Rectangle {
      width: parent ? parent.width : 0
      height: root.sectionHeightForBindCount((sectionData.binds || []).length)
      color: "transparent"
      radius: Style.radiusM
      border.width: 1
      border.color: Color.mOutline

      ColumnLayout {
        id: sectionColumn
        anchors.fill: parent
        anchors.margins: root.sectionPadding
        spacing: 4

        NText {
          Layout.fillWidth: true
          Layout.preferredHeight: root.sectionHeaderHeight
          text: sectionData.title
          font.pointSize: Style.fontSizeM
          font.weight: Font.Bold
          color: Color.mPrimary
          elide: Text.ElideRight
        }

        Repeater {
          model: sectionData.binds || []

          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.rowHeight
            spacing: Style.marginXXS

            Flow {
              Layout.preferredWidth: root.keyColumnWidth
              Layout.alignment: Qt.AlignVCenter
              spacing: 3

              Repeater {
                model: root.tokenizeKeys(modelData.keys)

                Loader {
                  sourceComponent: modelData.separator ? keySeparatorComponent : keyBadgeComponent
                  property var tokenData: modelData
                }
              }
            }

            NText {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              text: modelData.desc
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
                text: modelData.modes.toUpperCase()
                font.pointSize: 7
                font.weight: Font.Bold
                color: root.modeTextColor()
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

      result.push({ title: cat.title, binds: binds });
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

  // Relative luminance, WCAG 2.x. QML color channels are already sRGB in 0..1.
  function relativeLuminance(c) {
    function linear(v) {
      return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    }
    return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b);
  }

  function contrastRatio(a, b) {
    var la = relativeLuminance(a);
    var lb = relativeLuminance(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
  }

  // Every pill background is a theme role, so the label is just that role's
  // on-color - mTertiary gets mOnTertiary, not whatever mOnSurface happens to be.
  // The one case with no paired on-color is a user background override, and there
  // we pick the theme on-color that measures best against it.
  function readableTextColor(background, paired) {
    if (paired !== undefined) {
      return paired;
    }

    var candidates = [Color.mOnSurface, Color.mOnSurfaceVariant, Color.mSurface, Color.mOnPrimary, Color.mOnSecondary, Color.mOnTertiary];
    var best = candidates[0];
    var bestRatio = 0;
    for (var i = 0; i < candidates.length; i++) {
      var ratio = contrastRatio(background, candidates[i]);
      if (ratio > bestRatio) {
        bestRatio = ratio;
        best = candidates[i];
      }
    }
    return best;
  }

  function modeColor() {
    return keyColorModeOverride !== "" ? keyColorModeOverride : Color.mTertiary;
  }

  function modeTextColor() {
    if (keyLabelColorOverride !== "") return keyLabelColorOverride;
    // The mode pill only carries the theme's own on-color when its background is
    // still mTertiary; a custom keyColorMode has no on-color to pair with.
    return readableTextColor(modeColor(), keyColorModeOverride !== "" ? undefined : Color.mOnTertiary);
  }

  function getKeyColor(keyName) {
    if (keyName === "Space") return keyColorLeaderOverride !== "" ? keyColorLeaderOverride : Color.mPrimary;
    if (keyName === "Ctrl") return keyColorCtrlOverride !== "" ? keyColorCtrlOverride : Color.mSecondary;
    if (keyName === "Shift") return keyColorShiftOverride !== "" ? keyColorShiftOverride : Color.mTertiary;
    if (keyName === "Alt") return keyColorAltOverride !== "" ? keyColorAltOverride : Color.mTertiary;
    if (keyName === "Esc" || keyName === "Tab") return Color.mSurfaceVariant;
    return keyColorDefaultOverride !== "" ? keyColorDefaultOverride : Color.mSurfaceVariant;
  }

  // The on-color that goes with this key's default background, or undefined when
  // the user has overridden the background and no paired on-color exists.
  function getKeyOnColor(keyName) {
    if (keyName === "Space") return keyColorLeaderOverride !== "" ? undefined : Color.mOnPrimary;
    if (keyName === "Ctrl") return keyColorCtrlOverride !== "" ? undefined : Color.mOnSecondary;
    if (keyName === "Shift") return keyColorShiftOverride !== "" ? undefined : Color.mOnTertiary;
    if (keyName === "Alt") return keyColorAltOverride !== "" ? undefined : Color.mOnTertiary;
    if (keyName === "Esc" || keyName === "Tab") return Color.mOnSurfaceVariant;
    return keyColorDefaultOverride !== "" ? undefined : Color.mOnSurfaceVariant;
  }

  function getKeyTextColor(keyName) {
    if (keyLabelColorOverride !== "") return keyLabelColorOverride;
    return readableTextColor(getKeyColor(keyName), getKeyOnColor(keyName));
  }
}
