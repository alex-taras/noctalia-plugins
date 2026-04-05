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

    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name || "")

    implicitWidth: container.width
    implicitHeight: Style.barHeight

    function batteryIcon(pct, status) {
        if (status === "RECHARGING") return "󰂄"
        if (pct >= 80) return "󰁹"
        if (pct >= 60) return "󰂀"
        if (pct >= 40) return "󰁾"
        if (pct >= 20) return "󰁻"
        return "󰁺"
    }

    function batteryColor(pct) {
        if (pct < 20) return "#f87171"
        if (pct < 50) return "#fbbf24"
        return "#4ade80"
    }

    function deviceIcon(kind) {
        if (kind === "keyboard") return "󰌌"
        if (kind === "mouse")    return "󰍺"
        if (kind === "headset")  return "󰋌"
        return "󰤾"
    }

    function buildTooltipText() {
        if (!Local.SolaarService.data || !Local.SolaarService.data.devices) return ""

        const devices = Local.SolaarService.data.devices
        let lines = ""
        for (let i = 0; i < devices.length; i++) {
            const d = devices[i]
            const color = batteryColor(d.battery)
            if (i > 0) lines += "<br>"
            lines += deviceIcon(d.kind) + "  " + d.name
                + "  " + batteryIcon(d.battery, d.status)
                + " <span style='color:" + color + ";'>" + d.battery + "%</span>"
        }
        return "<div style='text-align: left; font-size: 150%;'>" + lines + "</div>"
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
                    if (Local.SolaarService.loading) return "󱊣  Loading..."
                    if (!Local.SolaarService.data)   return "󱊣  No Devices"
                    const count = Local.SolaarService.data.count || 0
                    return "󱊣  " + count + (count === 1 ? " Device" : " Devices")
                }
                color: Color.mOnSurface
                pointSize: Style.fontSizeS
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            if (Local.SolaarService.data) {
                TooltipService.show(root, buildTooltipText(), BarService.getTooltipDirection(root.screen?.name))
                tooltipRefreshTimer.start()
            }
        }

        onExited: {
            tooltipRefreshTimer.stop()
            TooltipService.hide()
        }
    }

    Timer {
        id: tooltipRefreshTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (mouseArea.containsMouse && Local.SolaarService.data) {
                TooltipService.updateText(buildTooltipText())
            }
        }
    }
}
