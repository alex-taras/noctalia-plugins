import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Location
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: "at-weather"
  property string section: "Weather"

  readonly property bool weatherReady: Settings.data.location.weatherEnabled && (LocationService.data.weather !== null)
  readonly property int currentWeatherCode: weatherReady ? LocationService.data.weather.current_weather.weathercode : 0
  readonly property bool isDay: weatherReady ? LocationService.data.weather.current_weather.is_day : true

  readonly property string weatherIcon: weatherReady ? LocationService.weatherSymbolFromCode(currentWeatherCode, isDay) : "weather-cloud-off"

  readonly property int weatherTemp: {
    if (!weatherReady)
      return 0
    var temp = LocationService.data.weather.current_weather.temperature
    if (Settings.data.location.useFahrenheit) {
      temp = LocationService.celsiusToFahrenheit(temp)
    }
    return Math.round(temp)
  }

  readonly property string weatherLocation: {
    if (!weatherReady)
      return ""
    const chunks = Settings.data.location.name.split(",")
    return chunks[0]
  }

  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name || "")

  implicitWidth: row.implicitWidth + Style.marginM * 2
  implicitHeight: Style.barHeight

  Rectangle {
    id: container
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: parent.width
    height: capsuleHeight

    color: Style.capsuleColor
    radius: Style.radiusM

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: Style.marginS

    NIcon {
      icon: root.weatherIcon
      color: weatherReady ? Color.mOnSurface : Color.mOnSurfaceVariant
      pointSize: Style.fontSizeM
    }

    NText {
      text: weatherReady ? root.weatherTemp + "°" : ""
      color: Color.mOnSurface
      pointSize: Style.fontSizeS
    }

    NText {
      text: root.weatherLocation
      color: Color.mOnSurface
      pointSize: Style.fontSizeS
    }
  }
  }
}
