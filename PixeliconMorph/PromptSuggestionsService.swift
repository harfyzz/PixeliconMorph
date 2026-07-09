import Foundation
import FoundationModels

@Generable
struct PromptContinuations {
    @Guide(description: "Between 1 and 3 short phrases (6–10 words each) that naturally continue and improve the user's prompt. Each phrase is additive — it will be appended after what the user has already typed and must flow as one continuous sentence, so do NOT repeat any existing words. Infer the task domain (image, video, code, app, writing, plan, etc.) from what the user has written and tailor each phrase to that domain. No leading punctuation.")
    var phrases: [String]
}

enum PromptSuggestionsService {
    private static let instructions = """
    You are a prompt-writing assistant. Users of an AI tool often trail off, forget key details, \
    or don't know how to structure a request. Your job is to suggest short additive phrases that \
    help finish or sharpen what they've started typing.

    The prompt could be for anything: image or video generation, code, an app idea, a document, \
    a plan. Read the entire text the user has typed so far, infer the domain and intent, then \
    suggest the pieces most likely missing to make it actionable.

    CRITICAL — grammatical join:
    • Your phrase is appended DIRECTLY after the user's text with exactly one space between.
    • Look at the LAST WORD the user typed. Your FIRST word must grammatically follow it so \
      the combined text reads as one continuous, correct sentence.
      – Last word is an article ("a", "an", "the") → start with a noun (or adjective + noun).
        e.g. "A photorealistic aerial view of a" → "dense tropical rainforest at dawn"
      – Last word is a preposition ("on", "in", "with", "of", "at", "by", "to", "from", …) → \
        start with a noun phrase.
        e.g. "a cat sitting on" → "a worn red velvet couch"
      – Last word is a conjunction ("and", "but", "or", "while") → start with a matching clause \
        fragment.
      – Last word ends a clause (period, comma, semicolon) → start a new independent fragment.
      – Last word is a verb → continue with its object or a modifier.
    • Never begin with a word that duplicates or contradicts what came right before it.

    Other rules:
    • Do not repeat words the user has already written.
    • Tailor phrases to the inferred domain — visual detail for images/video, specs and \
      constraints for code, requirements and user flow for apps, structure and tone for writing.
    • Prioritize what's missing to make the request specific and buildable, not filler.
    • No leading punctuation. No leading conjunctions unless the phrase genuinely needs one.
    """

    /// Streams up to 3 continuation phrases as the on-device model generates them.
    /// Yields an updated array on each partial snapshot; finishes when the model is done.
    static func stream(from prompt: String) -> AsyncThrowingStream<[String], Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 4 else {
                    continuation.finish()
                    return
                }
                guard case .available = SystemLanguageModel.default.availability else {
                    continuation.finish()
                    return
                }
                do {
                    let session = LanguageModelSession(instructions: instructions)
                    let stream = session.streamResponse(
                        to: "User's prompt so far: \"\(trimmed)\"",
                        generating: PromptContinuations.self
                    )
                    for try await snapshot in stream {
                        if Task.isCancelled { break }
                        let phrases = Array((snapshot.content.phrases ?? []).prefix(3))
                        continuation.yield(phrases)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
