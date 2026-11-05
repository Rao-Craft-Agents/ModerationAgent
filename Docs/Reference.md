# ModerationAgent reference

How the `moderation` agent is found, what a call takes and answers, what it writes, how the package is made, and
how to test it. What it is for is in the [README](../README.md); the agent standard it follows is Granite's
[Schema/GraniteAgent.md](https://github.com/riteshpakala/Granite/blob/main/Schema/GraniteAgent.md).

## How an app finds it

ModerationAgent is a `GraniteAgentPackage`, and it carries a record in its binary:

```swift
@used @section("__DATA_CONST,__granite")
let moderationRecord: GraniteRoster.Record = { GraniteRoster.record(ModerationAgent.self) }
```

In [Craft](https://github.com/riteshpakala/Craft), install it from the Agent Store or with
`craft agents add https://github.com/Rao-Craft-Agents/ModerationAgent.git`, then say `$moderation` in a request:

```
$moderation keep spoilers and crypto spam out of the recipe feed, and blur food photos the model flags
```

The model writes the call; it shows on Craft's agent map as `moderation-1`, and the files it names are built and
tested with the turn.

## What a call takes and answers

| Field | | |
|---|---|---|
| `name` | optional | the package's name, module and folder; `ModerationKit` when left out |
| `into` | optional | the package's folder, relative to the project; `Packages/<name>` when left out |
| `keywords` | optional | the terms a new install filters: `spoiler`, `buy now`, `crypto*` |
| `label` | optional | the image classifier's label that means unsafe; `NSFW` when left out |
| `threshold` | optional | the score from 0 to 1 from which an image is blurred; 0.8 when left out |
| `modelURL` | optional | the https URL of an `.mlmodel` the app downloads once, compiles and keeps |
| `features` | optional | of `keywords`, `images`, `overlay`, `editor`; all four when left out |
| `link` | optional | whether to link into the `.xcodeproj` or `Package.swift` in the folder; true when left out |
| `directory` | the host's | the folder the host works in; a host fills it and does not show it to a model |

```json
{}
{"keywords": ["spoiler", "store-bought", "crypto*"], "threshold": 0.7}
{"modelURL": "https://models.example.com/food-photo-safety.mlmodel", "label": "unsafe"}
{"features": ["keywords", "editor"], "keywords": ["spoiler"]}
{"name": "RecipeSafety", "into": "Packages/RecipeSafety", "link": false}
```

The answer is a `ModerationResult`: every file written (`path`, `paths`, absolute, the project or manifest it edited
among them), the package's name and folder, its parts, where it was linked, the files an earlier call wrote that this
one left out (removed), and a sentence for anything it changed beside the package, like a deployment target raised.

## What it writes

| Part | Files |
|---|---|
| always | `Package.swift` (iOS 17, macOS 14, Swift 6, no dependencies), `ModerationPolicy`, `ModeratedContent`, `ModerationReason`, `Verdict`, `ModerationAction`, `Moderator` |
| `keywords` | `KeywordFilter`: every term compiled once into a tree of words and matched in one pass; whole words, any case, accents or width, phrases, `*` for any letters or any one word; the term, field and words of each match; `KeywordRule`, a term with its switch and fields |
| `images` | `ImageSafety`, `CoreMLImageSafety`: a classifier the app bundles, keeps compiled, or downloads once from a URL, compiled on the device and kept in Application Support; run through Vision on a queue of its own; images loaded with URLSession, decoded to 512 pixels, their scores kept by URL |
| `overlay` | `censorOverlay(_:)`: blurred under the reason's symbol and words until a tap or a click, hidden content folded to a line with a Show button, hidden from VoiceOver while covered |
| `editor` | `KeywordListEditor`: the filter's switch, what a match does, add and remove terms, each term's switch and fields |
| tests | the keyword filter, the policy, and the moderator with a stub image screen |

`Moderator` is an actor: judging never runs on the main thread, a verdict is kept by the content's id while the
content and the policy stay the same, and an image that cannot be screened never hides content. No model ships in
the package.

## How the package is made

| Step | What |
|---|---|
| Read | every field checked; every problem said at once, and nothing written |
| Write | every file from a template, the call's name, terms, label, threshold and URL in it; parts left out leave no code behind |
| Link | the project file edited as text, as Xcode writes it: the package reference, a product dependency and a build file for every application target, a deployment target below iOS 17 or macOS 14 raised; or the manifest's dependency, products and platforms; a second call adds nothing |
| Check | every file staged, parsed with `swiftc -parse`, then moved into the project together |
| Again | the same name writes the package again and removes the parts left out; a folder holding another package is refused |

No model is asked: the same call makes the same files every time.

## Testing

```
swift test                       # the record, the schema, the guide, every set of parts, both linkers, a call through the roster
MODERATION_BUILD=1 swift test    # the packages built and tested, for macOS and the iOS simulator, linked into an app and a package
```

The gated test builds and tests the whole package and three smaller ones, builds it for the iOS simulator, builds an
app project it is linked into for macOS and iOS, and runs a tool in a package it is linked into that scores images
with a real (tiny, made-for-the-test) Core ML classifier: downloaded, compiled, kept, and loaded again from the cache.
