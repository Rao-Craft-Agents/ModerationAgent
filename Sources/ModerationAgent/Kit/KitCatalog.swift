//  WHAT: Every file the generated package can hold, in the order a call writes them: the manifest first, then the
//        sources part by part, then the tests. A call writes the ones that belong to its parts.

import Foundation

enum KitCatalog {
    static let all: [KitTemplate] = [
        PackageTemplates.manifest,
        PackageTemplates.readme,
        PackageTemplates.gitignore,
        KeywordTemplates.token,
        KeywordTemplates.tokenizer,
        KeywordTemplates.pattern,
        KeywordTemplates.node,
        KeywordTemplates.match,
        KeywordTemplates.filter,
        KeywordTemplates.rule,
        KeywordTemplates.scope,
        ImageTemplates.safety,
        ImageTemplates.error,
        ImageTemplates.coreML,
        ImageTemplates.classifier,
        ImageTemplates.store,
        ImageTemplates.loader,
        ModerationTemplates.action,
        ModerationTemplates.policy,
        ModerationTemplates.content,
        ModerationTemplates.image,
        ModerationTemplates.reason,
        ModerationTemplates.verdict,
        ModerationTemplates.cache,
        ModerationTemplates.screeningModerator,
        ModerationTemplates.textModerator,
        ViewTemplates.overlay,
        ViewTemplates.field,
        ViewTemplates.row,
        ViewTemplates.editor,
        TestTemplates.keywordFilter,
        TestTemplates.policy,
        TestTemplates.moderator,
        TestTemplates.stub,
        TestTemplates.sample,
    ]
}
