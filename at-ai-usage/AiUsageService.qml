pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
    id: service

    property real fiveHourUtil: 0
    property string fiveHourResetsAt: ""
    property real sevenDayUtil: 0
    property string sevenDayResetsAt: ""
    property bool extraUsageEnabled: false
    property real extraUsageUtil: 0
    property string error: ""
    property bool loading: false

    property string credentialsPath: "~/.claude/.credentials.json"
    property int refreshIntervalMinutes: 5
    property bool showExtraUsage: true

    property string settingsBuffer: ""
    property string usageBuffer: ""

    // Load settings.json
    Process {
        id: settingsReader
        command: ["cat", Qt.resolvedUrl("settings.json").toString().replace("file://", "")]

        stdout: SplitParser {
            onRead: data => {
                settingsBuffer += data
            }
        }

        onExited: () => {
            try {
                const s = JSON.parse(settingsBuffer)
                settingsBuffer = ""

                const intervalChanged = (s.refreshIntervalMinutes || 5) !== refreshIntervalMinutes

                credentialsPath = s.credentialsPath || "~/.claude/.credentials.json"
                refreshIntervalMinutes = s.refreshIntervalMinutes || 5
                showExtraUsage = s.showExtraUsage !== undefined ? s.showExtraUsage : true

                if (intervalChanged) {
                    refreshTimer.interval = refreshIntervalMinutes * 60000
                }
            } catch (e) {
                Logger.e("AiUsage", "Failed to parse settings: " + e)
                settingsBuffer = ""
            }
        }
    }

    // Fetch usage via the fetch script
    Process {
        id: usageFetcher
        command: [Qt.resolvedUrl("ai_usage_fetch.sh").toString().replace("file://", ""), credentialsPath]

        stdout: SplitParser {
            onRead: data => {
                usageBuffer += data
            }
        }

        onExited: () => {
            loading = false
            try {
                const result = JSON.parse(usageBuffer)
                usageBuffer = ""

                if (result.error) {
                    error = result.error
                    return
                }

                error = ""
                fiveHourUtil = result.five_hour ? (result.five_hour.utilization || 0) : 0
                fiveHourResetsAt = result.five_hour ? (result.five_hour.resets_at || "") : ""
                sevenDayUtil = result.seven_day ? (result.seven_day.utilization || 0) : 0
                sevenDayResetsAt = result.seven_day ? (result.seven_day.resets_at || "") : ""
                extraUsageEnabled = result.extra_usage ? (result.extra_usage.is_enabled || false) : false
                extraUsageUtil = result.extra_usage ? (result.extra_usage.utilization || 0) : 0
            } catch (e) {
                Logger.e("AiUsage", "Failed to parse usage response: " + e)
                error = "parse_error"
                usageBuffer = ""
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: refreshIntervalMinutes * 60000
        running: true
        repeat: true
        onTriggered: fetchUsage()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            settingsBuffer = ""
            settingsReader.running = true
        }
    }

    function fetchUsage() {
        loading = true
        usageBuffer = ""
        usageFetcher.running = true
    }

    Component.onCompleted: {
        fetchUsage()
    }
}
