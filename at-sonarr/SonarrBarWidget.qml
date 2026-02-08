import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "." as Local

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    readonly property color successColor: "#4ade80"
    readonly property color warningColor: "#fbbf24"
    readonly property color errorColor: Color.mError
    readonly property color neutralColor: Color.mOnSurface

    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name || "")

    implicitWidth: container.width
    implicitHeight: Style.barHeight

    function buildTooltipText() {
        if (!Local.SonarrService.data) return ""

        const today = Local.SonarrService.data.today || "No shows"
        const tomorrow = Local.SonarrService.data.tomorrow || "No shows"

        return "<div style='text-align: left; font-size: 150%;'>TODAY:<br>" + today.replace(/\n/g, "<br>") + "<br>━━━━━━━━━━━━━━━━━━━━━━━━━━<br><br>TOMORROW:<br>" + tomorrow.replace(/\n/g, "<br>") + "</div>"
    }

    Rectangle {
        id: container
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: contentRow.implicitWidth + Style.marginM * 2
        height: capsuleHeight

        color: Style.capsuleColor
        radius: Style.radiusM

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Style.marginXS

            NText {
                text: {
                    if (Local.SonarrService.loading) {
                        return "  Loading..."
                    } else if (!Local.SonarrService.data) {
                        return "  Configure Sonarr"
                    } else {
                        const count = Local.SonarrService.data.count || 0
                        return "  " + count + (count === 1 ? " Show Today" : " Shows Today")
                    }
                }
                color: Color.mOnSurface
                pointSize: Style.fontSizeS
                horizontalAlignment: Text.AlignLeft
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        onEntered: {
            if (Local.SonarrService.data) {
                TooltipService.show(root, buildTooltipText(), BarService.getTooltipDirection(root.screen?.name))
                tooltipRefreshTimer.start()
            }
        }

        onExited: {
            tooltipRefreshTimer.stop()
            TooltipService.hide()
        }

        onClicked: {
            TooltipService.hide()
            if (Local.SonarrService.sonarrUrl) {
                const calendarUrl = Local.SonarrService.sonarrUrl + "/calendar"
                Qt.openUrlExternally(calendarUrl)
            }
        }
    }

    Timer {
        id: tooltipRefreshTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (mouseArea.containsMouse && Local.SonarrService.data) {
                TooltipService.updateText(buildTooltipText())
            }
        }
    }
}
