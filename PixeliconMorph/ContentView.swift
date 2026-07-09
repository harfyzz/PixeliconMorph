//
//  ContentView.swift
//  PixeliconMorph
//
//  Created by Afeez Yunus on 07/07/2026.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State var morphIcon = RiveViewModel(fileName: "pixelmorph", stateMachineName: "Main")
    @State private var inputText = ""
    @State private var suggestions: [String] = []

    // MARK: - Preview state
    /// Index of the suggestion the user is currently previewing via ⌥+N.
    /// Non-nil means ⌥ is held and a suggestion is tentatively shown in the field.
    @State private var previewedIndex: Int? = nil
    /// Snapshot of `inputText` taken at the start of a preview, so we can
    /// restore it when the user cycles to a different ⌥N.
    @State private var baseText: String = ""

    // MARK: - Motion vocabulary
    /// Springs are the default state-driven curve; `nil` under reduced motion.
    private var stateSpring: Animation? {
        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85)
    }
    /// Snappier spring for rapid, interruptible interactions like ⌥N cycling.
    private var quickSpring: Animation? {
        reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.9)
    }

    var body: some View {
        ZStack {
            Color("bg").ignoresSafeArea()

            VStack(spacing: 0) {
                topArea
                PromptInputField(
                    text: $inputText,
                    isPreviewing: previewedIndex != nil,
                    previewBaseText: baseText,
                    previewedSuggestionText: previewedIndex.map { suggestions[$0] } ?? "",
                    onOptionNumberPressed: previewSuggestion,
                    onOptionReleased: commitPreview
                )
                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 120)
        }
        .task(id: inputText) {
            // Don't touch anything while a preview is active — inputText will
            // be changing as the user cycles ⌥N.
            guard previewedIndex == nil else { return }

            // As soon as the user resumes typing, drop stale suggestions so
            // the Rive view returns while we wait + stream. New phrases
            // trigger the swap back only when they actually arrive.
            if !suggestions.isEmpty {
                withAnimation(stateSpring) {
                    suggestions = []
                }
            }
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await streamSuggestions()
        }
    }

    /// Cross-fades between the Rive icon (idle) and the suggestion stack
    /// (when the model has phrases to offer). Fixed height keeps the input
    /// anchored so it doesn't shift as content swaps.
    private var topArea: some View {
        ZStack {
            if suggestions.isEmpty {
                morphIcon.view()
                    .frame(width: 80, height: 80)
                    .transition(reduceMotion ? .opacity : .blurFade)
                    .padding(.bottom, 32)
            } else {
                SuggestionStack(
                    suggestions: suggestions,
                    highlightedIndex: previewedIndex,
                    onAccept: accept
                )
                .frame(width: 314)
                .transition(reduceMotion ? .opacity : .blurFade)
            }
        }
        .frame(width: 350, height: 120)
        .animation(stateSpring, value: suggestions.isEmpty)
    }

    // MARK: - Suggestion handling

    /// Immediate accept (tap or click a chip).
    private func accept(_ suggestion: String) {
        let joiner = inputText.hasSuffix(" ") || inputText.isEmpty ? "" : " "
        inputText += joiner + suggestion
        withAnimation(stateSpring) {
            suggestions = []
        }
    }

    /// Handles ⌥N. On macOS: tentatively preview until ⌥ is released
    /// (`commitPreview`). On iOS: accept immediately — there's no SwiftUI
    /// way to observe modifier-key release, so preview would never commit.
    private func previewSuggestion(digit: Int) {
        let index = digit - 1
        guard index < suggestions.count else { return }

        #if os(macOS)
        // First ⌥N of this preview session — snapshot the user's real text so
        // cycling to a different ⌥N restores from the same base.
        if previewedIndex == nil {
            baseText = inputText
        }
        let joiner = baseText.hasSuffix(" ") || baseText.isEmpty ? "" : " "
        // Snappy spring so rapid ⌥1 → ⌥2 → ⌥3 cycling interrupts cleanly
        // instead of stacking separate ease curves.
        withAnimation(quickSpring) {
            previewedIndex = index
            inputText = baseText + joiner + suggestions[index]
        }
        #else
        accept(suggestions[index])
        #endif
    }

    /// User released ⌥. Commit whatever is currently previewed and clear the stack.
    private func commitPreview() {
        guard previewedIndex != nil else { return }
        withAnimation(stateSpring) {
            previewedIndex = nil
            suggestions = []
        }
    }

    @MainActor
    private func streamSuggestions() async {
        do {
            for try await phrases in PromptSuggestionsService.stream(from: inputText) {
                // Animate whenever the number of chips changes — this covers
                // both the initial Rive → suggestions swap and each subsequent
                // chip streaming in, so the VStack expansion springs smoothly
                // instead of snapping.
                if phrases.count != suggestions.count {
                    withAnimation(stateSpring) {
                        suggestions = phrases
                    }
                } else {
                    // Text-only updates (tokens filling in an existing chip) —
                    // plain assignment so per-token stutter doesn't appear.
                    suggestions = phrases
                }
            }
        } catch {
            // Silent — leave prior suggestions in place.
        }
    }
}

#Preview {
    ContentView()
}
