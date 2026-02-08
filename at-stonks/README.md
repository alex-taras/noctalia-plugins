# Stocks Ticker

A simple stocks ticker widget that displays real-time stock prices and changes in your Noctalia bar using the Finnhub API.

## Features

- Real-time stock price updates every 5 minutes
- Color-coded price indicators (green for positive, red for negative changes)
- Auto-scrolling support for multiple stocks
- Configurable widget width with content-hugging behavior
- Live settings updates without requiring reload
- Internationalization support (English, German, French, Italian, Spanish, Romanian)

## Installation

This plugin is available in the [noctalia-plugins](https://github.com/noctalia-dev/noctalia-plugins) repository.

## Configuration

The plugin can be configured through the settings panel:

- **Finnhub API Key**: Your API key from [finnhub.io](https://finnhub.io) (free tier available)
- **Stock Symbols**: Comma-separated list of stock symbols to track (e.g., `AAPL,TSLA,GOOG`)
- **Minimum Widget Width**: Width in pixels (100-800). Widget will hug content up to this maximum
- **Auto-scroll**: Enable/disable automatic scrolling when content exceeds the widget width

Settings are automatically reloaded within 1-2 seconds of saving.

## Usage

### Display
Shows stock information in the format: `SYMBOL $price (+/-change) | SYMBOL ...`

### Behavior
- Prices update automatically every 5 minutes
- Color coding: green (#4ade80) for positive changes, red for negative changes
- Auto-scrolling creates a seamless loop when enabled and content overflows

## Requirements

- **Noctalia**: 4.2.5 or higher
- **System dependencies**: `curl`, `bash`

## Technical Details

### Data Source
The plugin uses the [Finnhub API](https://finnhub.io) to fetch real-time stock quotes. The free tier supports:
- 60 API calls per minute
- Real-time data for US stocks
- Basic quote information (current price, change, percentage change)

### Update Mechanism
- Settings are polled every 1-2 seconds for changes
- Stock data is refreshed every 5 minutes
- Data is only re-fetched when symbols or API key changes

### Architecture
- **StonksService.qml**: Singleton service managing API calls and data state
- **StonksBarWidget.qml**: Bar widget component with dynamic width and scrolling
- **stocks_fetch.sh**: Bash script handling Finnhub API requests and JSON formatting
- **StonkSettings.qml**: Configuration panel with live preview
- **i18n/**: Translation files for internationalization (currently supports: en, de, fr, it, es, ro)

### Internationalization
The plugin automatically detects the system locale from Noctalia settings and loads the appropriate translation file. Currently supported languages:
- English (en) - default/fallback
- German (de)
- French (fr)
- Italian (it)
- Spanish (es)
- Romanian (ro)

Community contributions for additional languages are welcome. Add translation files to the `i18n/` directory following the existing JSON structure.
