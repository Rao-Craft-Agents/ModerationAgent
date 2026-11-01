//  WHAT: The generated package's manifest, readme and ignore file.
//  PIN:  EDIT THE TEMPLATE, THEN BUILD IT. `MODERATION_BUILD=1 swift test` renders every set of parts and builds
//        and tests each package for real.

import Foundation

enum PackageTemplates {
    static let manifest = KitTemplate("Package.swift", text: ##"""
// swift-tools-version:6.0
// {{name}}: on-device content safety for the app: a policy, a moderator that judges content against it, and what
// the app needs to act on a verdict. Nothing leaves the device, and no model ships here.

import PackageDescription

let package = Package(
    name: "{{name}}",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "{{name}}", targets: ["{{name}}"]),
    ],
    targets: [
        .target(
            name: "{{name}}",
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(
            name: "{{name}}Tests",
            dependencies: ["{{name}}"],
            swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
"""##)

    static let readme = KitTemplate("README.md", text: ##"""
# {{name}}

On-device content safety for the app. A `Moderator` holds each post, comment or profile to a `ModerationPolicy` the
app keeps with its settings, and answers a `Verdict`: allow it, blur it under its reason, or hide it. Nothing leaves
the device, and no model ships in this package.

## Judging content

```swift
import {{name}}

{{#images}}
let moderator = Moderator(policy: policy, imageSafety: CoreMLImageSafety(source: .bundled("ImageSafety")))
{{/images}}
{{^images}}
let moderator = Moderator(policy: policy)
{{/images}}

let verdict = await moderator.judge(ModeratedContent(
    id: post.id,
{{#keywords}}
    text: ["title": post.title, "body": post.body],
{{/keywords}}
{{#images}}
    images: post.imageURLs.map(ModeratedImage.url),   // or .data(bytes), or .image(cgImage) already decoded
{{/images}}
    flags: post.isSensitive ? ["nsfw"] : []
))
```

`verdict.hides` says to leave the post out of a list, and `verdict.reason` says why it is blurred or hidden.

The moderator is an actor, so judging never runs on the main thread; `judge(_:)` of an array answers a page of a feed
at once, by id. `update(_:)` hands it the policy again when the person changes a setting. What the source says of
the content is judged first: the policy's `flags` (`["nsfw": .blur, "bot": .hide]`) act on the content's.
{{#keywords}}

## Keywords

`KeywordFilter` compiles every term once and finds them in one pass over a text's words, so a list of thousands costs
memory, not time a post. A term matches whole words (`ass` is not in `class`), whatever their case, accents or width
(`cafe` finds `Café`); `*` stands for any letters inside a word (`spoil*`, `*coin`, `c*t`) and, alone, for any one
word of a phrase (`free * money`). A rule may look in some fields only (`KeywordRule("spoiler", fields: ["title"])`),
and a match names the term, the field and the words as written. `redacting(_:)` masks the matched words instead.
{{/keywords}}
{{#images}}

## Images

`CoreMLImageSafety` runs an image classifier the app provides through Vision; an image's score is the classifier's
confidence in the label that means unsafe ({{labelText}} unless another is given), and the policy blurs from
`blurThreshold` ({{threshold}}) and, when `hideThreshold` is set, hides from it. The model comes from one of:

- `.bundled("Name")`: an `.mlmodel` added to the app target, which Xcode compiles into the bundle;
- `.compiled(url)`: a compiled `.mlmodelc` on disk;
- `.remote(url)`: an `.mlmodel` downloaded on first use, compiled on the device and kept in Application Support,
  excluded from backups.
{{#modelURL}}

`CoreMLImageSafety()` uses `.remote` with this app's model, {{modelURLText}}.
{{/modelURL}}

Choose a model whose licence fits the app. An image that cannot be loaded or scored never hides content: it is judged
again on the next look. Any other screen (a server's, a test's) conforms to `ImageSafety`.
{{/images}}
{{#overlay}}

## Showing a verdict

```swift
PostCard(post)
    .censorOverlay(verdict)
```

Blurred content shows its reason and a tap (a click on a Mac) shows it; hidden content folds to a line with a Show
button. While covered, the content is hidden from VoiceOver and takes no touches.
{{/overlay}}
{{#editor}}

## Editing the list

```swift
NavigationLink("Filtered words") {
    KeywordListEditor(policy: $settings.policy, fields: [KeywordField("title", title: "Titles"), KeywordField("body", title: "Posts")])
}
```

It edits a `ModerationPolicy` binding: the filter's switch, what a match does, and each term with its own switch.
{{/editor}}

## Tests

```
swift test
```
"""##)

    static let gitignore = KitTemplate(".gitignore", text: ##"""
.DS_Store
/.build
/.swiftpm
xcuserdata/
"""##)
}
