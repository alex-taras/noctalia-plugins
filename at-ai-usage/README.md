# AI Usage

Bar widget showing Claude subscription rate-limit usage: 5-hour rolling window and 7-day (weekly) window, plus pay-as-you-go extra usage credits if enabled on your account.

## How it works

Reads the OAuth access token straight from Claude Code's own credentials file (`~/.claude/.credentials.json`) and calls the same endpoint Claude Code's `/status` uses internally: `GET https://api.anthropic.com/api/oauth/usage`.

**This is unofficial and undocumented.** No SLA, no guarantee it keeps working across Anthropic or Claude Code changes. It requires Claude Code to be logged in (Pro/Max subscription OAuth, not an API key) on the same machine.

## Configuration

- **Credentials File Path**: path to Claude Code's `.credentials.json` (default `~/.claude/.credentials.json`)
- **Refresh Interval**: how often to poll, in minutes (default 5)
- **Warn / Danger Threshold**: utilization % at which the widget turns yellow / red
- **Show Pay-as-you-go Credits**: also show extra usage credit utilization if your account has it enabled

Click the widget to force an immediate refresh.

## Requirements

- Claude Code logged in via subscription OAuth on this machine
- `curl`, `bash`, `grep`, `sed`

## Architecture

- **ai_usage_fetch.sh**: reads the access token, curls the usage endpoint, prints the raw JSON
- **AiUsageService.qml**: singleton polling settings + fetching usage on a timer
- **AiUsageBarWidget.qml**: compact bar widget, color-coded by threshold
- **AiUsageSettings.qml**: settings panel
