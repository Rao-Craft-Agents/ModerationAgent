# Testing ModerationAgent

## Conformance on Hearth

Level 1 of the regime: the call a model should write, sent straight to the installed runner over its wire
(granite-agent/1) with no model, on a copy of Hearth as the journey left it (services, mock data and loom's views
made), then checked by building, testing and screenshotting the app. A pass here means the agent can produce the
result deterministically; whether Craft's model writes this call is tested by the prompts above.

### A keyword filter and its editor for Hearth

*2026-11-01 · straight to the runner, no model*

**The call**:

```json
{
  "keywords": [
    "spoiler",
    "store-bought"
  ],
  "features": [
    "keywords",
    "editor"
  ]
}
```

**Checks**:
- Packages/ModerationKit written and linked into Hearth-macOS and Hearth-iOS
- macOS build: BUILD SUCCEEDED
