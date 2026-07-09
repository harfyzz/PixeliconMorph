import SwiftUI

struct SuggestionStack: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let suggestions: [String]
    /// Index of the chip currently being previewed via ⌥+N (before commit).
    var highlightedIndex: Int? = nil
    let onAccept: (String) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(suggestions.prefix(3).enumerated()), id: \.offset) { index, suggestion in
                SuggestionChip(
                    text: suggestion,
                    shortcut: index + 1,
                    isHighlighted: highlightedIndex == index
                ) {
                    onAccept(suggestion)
                }
                .transition(reduceMotion ? .opacity : .blurScale)
            }
        }
        // Animate the VStack's layout as chips stream in, so preceding chips
        // slide up smoothly instead of snapping to make room.
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: suggestions.count)
    }
}

private struct SuggestionChip: View {
    let text: String
    let shortcut: Int
    var isHighlighted: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ShortcutBadge(number: shortcut, isHighlighted: isHighlighted)
                Text(text)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.702, green: 0.702, blue: 0.702))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .padding(.leading, 4)
            .padding(.trailing, 10)
            .padding(.vertical, 4)
            .background(Color(red: 0.133, green: 0.133, blue: 0.133))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
    }
}

private struct ShortcutBadge: View {
    let number: Int
    var isHighlighted: Bool = false

    // Non-highlighted (default) palette
    private let idleFill = Color(red: 0.102, green: 0.102, blue: 0.102)   // #1a1a1a
    private let idleStroke = Color(red: 0.220, green: 0.220, blue: 0.220) // #383838
    private let idleText = Color(red: 0.459, green: 0.459, blue: 0.459)   // #757575

    // Highlighted palette — inverts to light
    private let hotFill = Color(red: 0.925, green: 0.925, blue: 0.925)    // #ececec
    private let hotStroke = Color(red: 0.851, green: 0.851, blue: 0.851)  // #d9d9d9
    private let hotText = Color(red: 0.118, green: 0.118, blue: 0.118)    // #1e1e1e

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "option")
            Text("\(number)")
        }
        .font(.system(size: 12))
        .foregroundStyle(isHighlighted ? hotText : idleText)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHighlighted ? hotFill : idleFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isHighlighted ? hotStroke : idleStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 0, x: 0, y: 1)
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
    }
}
