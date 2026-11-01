//  WHAT: The generated package's SwiftUI: the censor overlay and the keyword list editor.
//  PIN:  EDIT THE TEMPLATE, THEN BUILD IT. `MODERATION_BUILD=1 swift test` renders every set of parts and builds
//        and tests each package for real.

import Foundation

enum ViewTemplates {
    static let overlay = KitTemplate("Sources/{{name}}/Views/CensorOverlay.swift", needs: [.overlay], text: ##"""
//  WHAT: Content covered by its verdict. Blurred content is drawn blurred under its reason until the person taps
//        (or clicks) to see it; hidden content is folded to a line with its reason and a button to show it; allowed
//        content is drawn as it is. Shown content can be covered again.
//  PIN:  NOTHING UNDER THE COVER IS READ OUT OR TAPPED. While covered, the content is hidden from VoiceOver, which
//        hears the reason and the action instead, and its own buttons and links take no touches.
//  PIN:  THE CONTENT STAYS THE SAME VIEW. Blurring and showing change only modifiers' values, so a video or an image
//        that loads under the cover keeps its state when it is shown; even the clip that keeps the blur inside the
//        content's bounds only widens when it is shown, so content that draws past its bounds is not cut.
//  PIN:  THE BLUR KEEPS TRANSPARENCY. An opaque blur would fill a card without a background with black.
//  PIN:  A NEW VERDICT COVERS AGAIN. A reused cell showing other content is never left revealed.

import SwiftUI

/// Covers a view by a verdict: blurred under its reason, or folded to a line, until the person shows it.
public struct CensorOverlay: ViewModifier {
    /// What the moderator decided about the content.
    public let verdict: Verdict
    @State private var isRevealed = false

    public init(_ verdict: Verdict) {
        self.verdict = verdict
    }

    public func body(content: Content) -> some View {
        Group {
            if case .hide(let reason) = verdict, !isRevealed {
                folded(reason)
            } else {
                content
                    .blur(radius: blurred == nil ? 0 : 24)
                    .clipShape(CoverClip(isCovering: blurred != nil))
                    .allowsHitTesting(blurred == nil)
                    .accessibilityHidden(blurred != nil)
                    .overlay {
                        if let reason = blurred { cover(reason) }
                    }
                    .overlay(alignment: .topTrailing) {
                        if isRevealed, verdict.reason != nil { coverAgainButton }
                    }
            }
        }
        .onChange(of: verdict) { isRevealed = false }
    }

    /// Why the content is blurred now; nil when it is shown as it is.
    private var blurred: ModerationReason? {
        if case .blur(let reason) = verdict, !isRevealed { return reason }
        return nil
    }

    private func cover(_ reason: ModerationReason) -> some View {
        Button(action: reveal) {
            ViewThatFits {
                VStack(spacing: 6) {
                    Image(systemName: reason.systemImage)
                        .font(.title3)
                    Text(reason.summary)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text(revealHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Image(systemName: reason.systemImage)
                    .padding(8)
                    .background(.regularMaterial, in: Circle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(reason.summary))
        .accessibilityHint(Text("Shows the content"))
    }

    private func folded(_ reason: ModerationReason) -> some View {
        HStack(spacing: 8) {
            Image(systemName: reason.systemImage)
                .accessibilityHidden(true)
            Text(reason.summary)
                .font(.subheadline)
            Spacer(minLength: 8)
            Button("Show", action: reveal)
                .buttonStyle(.borderless)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var coverAgainButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { isRevealed = false }
        } label: {
            Image(systemName: "eye.slash")
                .font(.footnote.weight(.semibold))
                .padding(8)
                .background(.thinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .padding(8)
        .accessibilityLabel(Text("Cover again"))
    }

    private var revealHint: LocalizedStringKey {
        #if os(macOS)
        "Click to show"
        #else
        "Tap to show"
        #endif
    }

    private func reveal() {
        withAnimation(.easeInOut(duration: 0.2)) { isRevealed = true }
    }

    /// The content's bounds while it is covered, so its blur stays inside them; far wider bounds once it is shown.
    private struct CoverClip: Shape {
        var isCovering: Bool

        func path(in rect: CGRect) -> Path {
            Path(isCovering ? rect : rect.insetBy(dx: -10_000, dy: -10_000))
        }
    }
}

extension View {
    /// Covers the view by `verdict`: blurred under its reason, or folded to a line, until the person shows it.
    public func censorOverlay(_ verdict: Verdict) -> some View {
        modifier(CensorOverlay(verdict))
    }
}
"""##)

    static let field = KitTemplate("Sources/{{name}}/Views/KeywordField.swift", needs: [.editor], text: ##"""
//  WHAT: A text field of the app's content that a keyword may be limited to: its key in `ModeratedContent.text`,
//        and its name for a person.

import Foundation

/// A text field a keyword may be limited to.
public struct KeywordField: Identifiable, Sendable {
    /// The field's key in `ModeratedContent.text`: `title`.
    public let id: String
    /// Its name for a person: "Titles".
    public let title: LocalizedStringResource

    public init(_ id: String, title: LocalizedStringResource) {
        self.id = id
        self.title = title
    }
}
"""##)

    static let row = KitTemplate("Sources/{{name}}/Views/KeywordRuleRow.swift", needs: [.editor], text: ##"""
//  WHAT: One term of the keyword list: its switch, the fields it looks in, and a menu to limit it to some fields or
//        remove it.

import SwiftUI

struct KeywordRuleRow: View {
    @Binding var rule: KeywordRule
    let fields: [KeywordField]
    let remove: () -> Void

    var body: some View {
        Toggle(isOn: $rule.isEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: rule.term)
                if !fields.isEmpty {
                    Text(scope)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contextMenu {
            if !fields.isEmpty {
                ForEach(fields) { field in
                    Toggle(isOn: looks(in: field)) { Text(field.title) }
                }
                Divider()
            }
            Button("Remove", systemImage: "trash", role: .destructive, action: remove)
        }
    }

    /// "In every field", or the fields it is limited to.
    private var scope: LocalizedStringKey {
        let names = fields.filter { rule.fields.contains($0.id) }.map { String(localized: $0.title) }
        return names.isEmpty ? "In every field" : "In \(names.joined(separator: ", "))"
    }

    /// Whether the rule looks in `field`, as a switch: limiting it to no field at all means every field.
    private func looks(in field: KeywordField) -> Binding<Bool> {
        Binding {
            rule.fields.contains(field.id)
        } set: { isOn in
            if isOn { rule.fields.insert(field.id) } else { rule.fields.remove(field.id) }
        }
    }
}
"""##)

    static let editor = KitTemplate("Sources/{{name}}/Views/KeywordListEditor.swift", needs: [.editor], text: ##"""
//  WHAT: The keyword list as a person edits it: the filter's switch, what a match does, a field to add a word or
//        phrase, and every term with a switch of its own; a term is removed by swiping it (iOS) or from its menu,
//        where it can also be limited to some fields. It edits a `ModerationPolicy` binding, so the app keeps the
//        policy the way it keeps any setting and hands it to its `Moderator`.
//  PIN:  A TERM IS LISTED ONCE. Adding `Spoiler` when `spoiler` is listed turns the listed one on instead.

import SwiftUI

/// Edits a policy's keyword list: add and remove terms, turn each on or off, and the filter itself.
public struct KeywordListEditor: View {
    @Binding private var policy: ModerationPolicy
    private let fields: [KeywordField]
    @State private var draft = ""
    @FocusState private var isDrafting: Bool

    /// - Parameters:
    ///   - policy: the policy whose keywords are edited.
    ///   - fields: the text fields a term may be limited to; none: every term looks in every field.
    public init(policy: Binding<ModerationPolicy>, fields: [KeywordField] = []) {
        _policy = policy
        self.fields = fields
    }

    public var body: some View {
        Form {
            Section {
                Toggle("Filter keywords", isOn: $policy.filtersKeywords)
                Picker("When a keyword matches", selection: $policy.keywordAction) {
                    ForEach(ModerationAction.allCases) { action in
                        Text(action.title).tag(action)
                    }
                }
            }
            Section {
                HStack {
                    TextField("New keyword", text: $draft, prompt: Text("Add a word or phrase"))
                        .labelsHidden()
                        .focused($isDrafting)
                        .onSubmit(add)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    Button(action: add) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!KeywordFilter.canMatch(draft))
                    .accessibilityLabel(Text("Add keyword"))
                }
                if policy.keywords.isEmpty {
                    Text("No keywords yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach($policy.keywords) { $rule in
                        KeywordRuleRow(rule: $rule, fields: fields) { remove(rule) }
                    }
                    .onDelete { offsets in policy.keywords.remove(atOffsets: offsets) }
                }
            } header: {
                Text("Keywords")
            } footer: {
                Text("Matches whole words, whatever their case or accents. Use * for any letters: spoil* also matches spoilers.")
            }
        }
        .formStyle(.grouped)
    }

    private func add() {
        let term = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard KeywordFilter.canMatch(term) else { return }
        let key = KeywordFilter.key(for: term)
        if let listed = policy.keywords.firstIndex(where: { KeywordFilter.key(for: $0.term) == key }) {
            policy.keywords[listed].isEnabled = true
        } else {
            policy.keywords.insert(KeywordRule(term), at: 0)
        }
        draft = ""
        isDrafting = true
    }

    private func remove(_ rule: KeywordRule) {
        policy.keywords.removeAll { $0.id == rule.id }
    }
}
"""##)
}
