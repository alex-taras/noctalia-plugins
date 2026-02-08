pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
    id: sonarrService

    property var data: null
    property bool loading: false
    property string sonarrHost: ""
    property string sonarrPort: ""
    property string sonarrUrl: ""
    property string apiKey: ""
    property string settingsBuffer: ""
    property string dataBuffer: ""

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
                const settings = JSON.parse(settingsBuffer)
                const newHost = settings.sonarrHost || ""
                const newPort = settings.sonarrPort || "8989"
                const newApiKey = settings.apiKey || ""
                const newUrl = newHost ? `http://${newHost}:${newPort}` : ""
                settingsBuffer = ""

                const urlChanged = newUrl !== sonarrUrl
                const apiKeyChanged = newApiKey !== apiKey

                sonarrHost = newHost
                sonarrPort = newPort
                sonarrUrl = newUrl
                apiKey = newApiKey

                if (sonarrUrl && apiKey && (urlChanged || apiKeyChanged || data === null)) {
                    dataFetcher.running = true
                } else if (!sonarrUrl || !apiKey) {
                    data = null
                    loading = false
                }
            } catch (e) {
                Logger.e("Sonarr", "Failed to parse settings: " + e)
                loading = false
            }
        }
    }

    Process {
        id: dataFetcher
        command: [Qt.resolvedUrl("sonarr_fetch.sh").toString().replace("file://", ""), sonarrUrl, apiKey]

        stdout: SplitParser {
            onRead: data => {
                dataBuffer += data
            }
        }

        onExited: () => {
            try {
                const result = JSON.parse(dataBuffer)
                data = result
                dataBuffer = ""
                loading = false
            } catch (e) {
                Logger.e("Sonarr", "Failed to parse data: " + e)
                loading = false
            }
        }
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: {
            if (sonarrUrl && apiKey) {
                dataBuffer = ""
                dataFetcher.running = true
            }
        }
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

    function fetchData() {
        loading = true
        settingsBuffer = ""
        dataBuffer = ""
        settingsReader.running = true
    }

    Component.onCompleted: {
        fetchData()
    }
}
