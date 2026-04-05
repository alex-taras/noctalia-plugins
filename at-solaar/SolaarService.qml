pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
    id: solaarService

    property var data: null
    property bool loading: false
    property string dataBuffer: ""

    Process {
        id: dataFetcher
        command: ["python3", Qt.resolvedUrl("solaar_fetch.py").toString().replace("file://", "")]

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
                Logger.e("Solaar", "Failed to parse data: " + e)
                loading = false
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            dataBuffer = ""
            dataFetcher.running = true
        }
    }

    function fetchData() {
        loading = true
        dataBuffer = ""
        dataFetcher.running = true
    }

    Component.onCompleted: {
        fetchData()
    }
}
