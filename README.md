# ModerationAgent

Keep what people post in your app safe to look at, decided on the device. One request gives the app a keyword
filter, an image check on a Core ML classifier you provide, and a moderator that decides for each post whether to
show it, blur it or hide it, and says why, with the SwiftUI that covers what it flags and a screen to edit the
keyword list. It is written as a local Swift package of plain SwiftUI that works in any app, with no Granite and no
other dependency in it, and linked into your project for you.

## What you can ask

```
$moderation keep spoilers and crypto spam out of the recipe feed, and blur food photos the model flags
$moderation the whole content-safety package for the app
$moderation filter spoiler and store-bought, with an editor for the list and no image checks
$moderation blur photos the classifier at https://models.example.com/food-photo-safety.mlmodel labels unsafe
```

Craft writes the call from your request, shows it on its agent map as `moderation-1`, and builds and tests what it
writes with the turn.

## What you get

- **A keyword filter.** Whole words in any case, accents or width, phrases, and `*` for any letters or any one word;
  every term compiled once and matched in one pass, with the term, field and words of each match.
- **An image check on your model.** A classifier the app bundles, or downloads once from a URL, compiles on the
  device and keeps; images scored through Vision on a queue of their own and blurred from the score you choose (0.8
  unless you say).
- **A moderator.** `Moderator` judges each piece of content into allow, blur or hide with the reason, never on the
  main thread, and keeps a verdict while the content and the policy stay the same. An image that cannot be screened
  never hides content.
- **The SwiftUI around it.** `censorOverlay(_:)` blurs flagged content under the reason until a tap or a click, folds
  hidden content to a line with a Show button and keeps it from VoiceOver while covered; `KeywordListEditor` turns the
  filter on and off, chooses what a match does, and adds and removes terms.
- **A policy and its tests.** `ModerationPolicy` for the app to persist, and tests of the filter, the policy and the
  moderator.

## How it works

- Every field is checked first; every problem is said at once, and nothing is written.
- Every file comes from a template, and no model is asked: the same call makes the same files every time, and a part
  you leave out leaves no code behind.
- It links the package into every app target of the Xcode project (or the `Package.swift`) in the folder, raising a
  deployment target below iOS 17 or macOS 14; a second call adds nothing, and the same name again writes the package
  again without the parts left out.
- Every file is parsed with `swiftc -parse` before any lands; what it makes is built and tested with the turn.

## Works well with

`moderation` brings the content safety of [Loom](https://github.com/riteshpakala/Loom) (its ModerationKit, NSFW
Shield and keyword filter) to any app that shows what people post. It sits beside the screens `loom` writes and the
pages `granite` makes: judge each post with the moderator, put `.censorOverlay(verdict)` on its card, and
`KeywordListEditor` in settings. Reporting, blocking accounts and moderation a server does are not its work.

## Get it

In Craft, install Moderation from the Agent Store, or run
`craft agents add https://github.com/Rao-Craft-Agents/ModerationAgent.git`, then say `$moderation` in a request.

## Requirements

- A Mac on macOS 14 or later, with Xcode.
- The package targets iOS 17 and macOS 14 in Swift 6, with no dependencies.
- Image checks need a Core ML classifier of your own, bundled with the app or at an https URL: no model ships in the
  package.
- MIT licensed.

## For developers

What a call takes and answers, every file it writes and how the package is made and linked are in the
[reference](Docs/Reference.md). It follows Granite's agent standard,
[Schema/GraniteAgent.md](https://github.com/riteshpakala/Granite/blob/main/Schema/GraniteAgent.md), and how it is
measured is [TESTING.md](TESTING.md).
