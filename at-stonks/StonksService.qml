pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
    id: stockService

    property var stocks: ({})
    property bool loading: false
    property string apiKey: ""
    property string symbols: ""
    property string settingsBuffer: ""
    property string stocksBuffer: ""

    // Process to read settings
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
                const newApiKey = settings.finnhubApiKey
                const newSymbols = settings.symbols.join(",")
                settingsBuffer = ""

                // Only refetch if symbols or API key changed
                const symbolsChanged = newSymbols !== symbols
                const apiKeyChanged = newApiKey !== apiKey

                apiKey = newApiKey
                symbols = newSymbols

                if (symbols && symbols.length > 0 && (symbolsChanged || apiKeyChanged || stocks === null || Object.keys(stocks).length === 0)) {
                    stocksFetcher.running = true
                } else if (!symbols || symbols.length === 0) {
                    stocks = ({})
                    loading = false
                }
            } catch (e) {
                Logger.e("Stonks", "Failed to parse settings: " + e)
                loading = false
            }
        }
    }

    // Process to fetch stocks
    Process {
        id: stocksFetcher
        command: [Qt.resolvedUrl("stocks_fetch.sh").toString().replace("file://", ""), apiKey, symbols]

        stdout: SplitParser {
            onRead: data => {
                stocksBuffer += data
            }
        }

        onExited: () => {
            try {
                const result = JSON.parse(stocksBuffer)
                stocks = result.stocks
                stocksBuffer = ""
                loading = false
            } catch (e) {
                Logger.e("Stonks", "Failed to parse stocks: " + e)
                loading = false
            }
        }
    }

    // Timer to refetch stocks every 5 minutes
    Timer {
        interval: 300000 // 5 minutes
        running: true
        repeat: true
        onTriggered: {
            if (symbols && symbols.length > 0) {
                stocksBuffer = ""
                stocksFetcher.running = true
            }
        }
    }

    // Timer to check for settings changes every 2 seconds
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
        stocksBuffer = ""
        settingsReader.running = true
    }

    Component.onCompleted: {
        fetchData()
    }
}
