import SwiftUI

/// Purely presentational: shows the text field, the animated placeholder, and
/// the controls row. Suggestions and AI orchestration live at the parent.
struct PromptInputField: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var text: String
    /// True while the user is holding ⌥ and previewing a suggestion. Drives
    /// the crossfade overlay so only the suggestion portion transitions.
    var isPreviewing: Bool = false
    /// The user's real (pre-preview) text. Rendered as a static layer during
    /// preview so it stays crisp while suggestions swap in and out.
    var previewBaseText: String = ""
    /// The suggestion currently being previewed. Rendered on top with a blur
    /// transition; the base portion of this overlay is invisible so it just
    /// reserves the correct wrapping position.
    var previewedSuggestionText: String = ""
    /// Fired when the user presses ⌥1 / ⌥2 / ⌥3 while the field is focused.
    /// Used to preview the Nth suggestion (not yet commit it).
    var onOptionNumberPressed: (Int) -> Void = { _ in }
    /// Fired when the user releases the ⌥ key. Used to commit whichever
    /// suggestion is currently being previewed.
    var onOptionReleased: () -> Void = {}

    private let placeholders = [
        "What would you like to create?",
        "A cinematic shot of a lonely cyclist",
        "An app to help me plan meals",
        "A landing page for a coffee brand",
        "A short story about a rogue AI",
        "A tool to organize my daily tasks",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    StaggeredText(texts: placeholders)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                        .allowsHitTesting(false)
                }
                TextField("", text: $text, axis: .vertical)
                    .lineLimit(1...6)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .textFieldStyle(.plain)
                    .opacity(isPreviewing ? 0 : 1)
                    .onKeyPress(.tab) {
                        guard text.isEmpty else { return .ignored }
                        text = StaggeredText.currentText(texts: placeholders)
                        return .handled
                    }
                    .onKeyPress(keys: ["1", "2", "3"], phases: .down) { press in
                        guard press.modifiers.contains(.option) else { return .ignored }
                        let digit: Int
                        switch press.key.character {
                        case "1": digit = 1
                        case "2": digit = 2
                        case "3": digit = 3
                        default: return .ignored
                        }
                        onOptionNumberPressed(digit)
                        return .handled
                    }
                    #if os(macOS)
                    .onModifierKeysChanged(mask: .option) { old, new in
                        // ⌥ release = commit whatever's being previewed.
                        // macOS only — iOS has no equivalent SwiftUI API.
                        if old.contains(.option) && !new.contains(.option) {
                            onOptionReleased()
                        }
                    }
                    #endif

                if isPreviewing {
                    // Static base layer — user's real text, never animates.
                    Text(previewBaseText)
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .allowsHitTesting(false)

                    // Overlay layer: invisible base (reserves wrapping) +
                    // visible suggestion. `.id` on the suggestion string makes
                    // SwiftUI swap the whole overlay each cycle, so only the
                    // suggestion glyphs actually change on screen — the base
                    // stays crisp underneath.
                    (Text(previewBaseText).foregroundColor(.clear)
                     + Text(previewJoiner + previewedSuggestionText)
                        .foregroundColor(.white))
                        .font(.system(size: 12))
                        .id(previewedSuggestionText)
                        .allowsHitTesting(false)
                        .transition(reduceMotion ? .opacity : .blurFade(radius: 6))
                }
            }

            controlsRow
        }
        .padding(12)
        .frame(width: 350)
        .background(Color(red: 0.102, green: 0.102, blue: 0.102))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Space to insert between base text and suggestion, unless the base
    /// already ends with whitespace or is empty.
    private var previewJoiner: String {
        previewBaseText.hasSuffix(" ") || previewBaseText.isEmpty ? "" : " "
    }

    private var controlsRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(red: 0.698, green: 0.698, blue: 0.698))

                Text("Agent")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(red: 0.118, green: 0.118, blue: 0.118))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    // .progressiveBlur(from: CGPoint(x: 35, y: 0), to: CGPoint(x: 90, y: 0), maxRadius: 6)
            }

            Spacer()
            
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 0.698, green: 0.698, blue: 0.698))

            trailingActionButton
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text.isEmpty)
    }

    /// Swaps between a waveform (voice) glyph when the field is empty and a
    /// primary send button (white circle + up-arrow) once the user starts typing.
    @ViewBuilder
    private var trailingActionButton: some View {
        if text.isEmpty {
            Image(systemName: "waveform")
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 0.698, green: 0.698, blue: 0.698))
                .frame(width: 22, height: 22)
                .transition(reduceMotion ? .opacity : .blurScale)
        } else {
            Button {
                // TODO: hook up send action
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.118, green: 0.118, blue: 0.118))
                    .frame(width: 22, height: 22)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(PressScaleButtonStyle())
            .transition(reduceMotion ? .opacity : .blurScale)
        }
    }
}
