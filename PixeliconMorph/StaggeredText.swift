import SwiftUI

/// A placeholder that cycles through multiple strings. Each cycle, a left-to-right
/// sweep crossfades from the current string to the next: the current text
/// fades out from the left, the next text fades in from the left. Both text
/// layers share a full-width frame so their transitions align in the same
/// pixel space — no per-glyph reflow, no flicker.
struct StaggeredText: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The text that would appear to be "primarily visible" right now, given
    /// the same time-based cycle the view uses. Callers (e.g. a TAB handler)
    /// use this to grab the placeholder the user is currently looking at.
    /// Pass the same `shimmerDuration` / `pauseDuration` values you configured
    /// on the view instance if you've overridden the defaults.
    static func currentText(
        texts: [String],
        shimmerDuration: Double = 1.8,
        pauseDuration: Double = 1.8
    ) -> String {
        guard !texts.isEmpty else { return "" }
        let cycle = shimmerDuration + pauseDuration
        let elapsed = Date().timeIntervalSinceReferenceDate
        let cycleNumber = Int(elapsed / cycle)
        let t = elapsed.truncatingRemainder(dividingBy: cycle)
        // Halfway through the shimmer, the "next" text is more visible than
        // the "current" one, so switch which text we report.
        let index = t < shimmerDuration / 2
            ? cycleNumber % texts.count
            : (cycleNumber + 1) % texts.count
        return texts[index]
    }

    /// Strings to cycle through, in order. Loops back to index 0 after the last.
    let texts: [String]
    /// Duration of one crossfade sweep.
    var shimmerDuration: Double = 1.8
    /// Rest between sweeps — the "next" text sits fully visible.
    var pauseDuration: Double = 1.8
    /// Width of the transition zone as a fraction of the container width (0…1).
    /// Larger = softer, more overlapping crossfade.
    var softness: Double = 0.1
    /// Seconds the reveal lags the hide. Small values (0.1–0.3) create a
    /// visible empty strip between the sweeping edges — a wipe-out-then-in
    /// feel. Both sweeps still finish within `shimmerDuration`.
    var revealDelay: Double = 0.07

    var body: some View {
        // Reduced motion: no cycling, no shimmer. Show a static placeholder.
        if reduceMotion {
            Text(texts.first ?? "")
        } else {
            animatedBody
        }
    }

    private var animatedBody: some View {
        let cycle = shimmerDuration + pauseDuration
        return TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let cycleNumber = Int(elapsed / cycle)
            let t = elapsed.truncatingRemainder(dividingBy: cycle)

            let safeCount = max(texts.count, 1)
            let currentText = texts[cycleNumber % safeCount]
            let nextText = texts[(cycleNumber + 1) % safeCount]

            let sweepDuration = max(0.01, shimmerDuration - revealDelay)
            let hidingProgress = progress(t: t, duration: sweepDuration)
            let revealingProgress = progress(t: t - revealDelay, duration: sweepDuration)

            ZStack(alignment: .leading) {
                Text(currentText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mask(sweepMask(progress: hidingProgress, revealing: false))
                Text(nextText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mask(sweepMask(progress: revealingProgress, revealing: true))
            }
        }
    }

    /// Ramps 0 → 1 over `duration`, offset by half the softness on either
    /// side so the transition zone starts and ends fully off-screen. Clamps
    /// before start and after end.
    private func progress(t: Double, duration: Double) -> Double {
        if t <= 0 { return -softness / 2 }
        if t >= duration { return 1 + softness / 2 }
        return (t / duration) * (1 + softness) - softness / 2
    }

    /// Linear-gradient mask that sweeps from left to right.
    /// - `revealing: true` — opaque behind the sweep, clear ahead. Reveals content.
    /// - `revealing: false` — clear behind the sweep, opaque ahead. Hides content.
    private func sweepMask(progress: Double, revealing: Bool) -> some View {
        let half = softness / 2
        let leftStop = max(0.0, min(1.0, progress - half))
        let rightStop = max(leftStop, min(1.0, progress + half))
        let inside = Color.black    // opaque — content shown
        let outside = Color.clear   // transparent — content hidden
        let colors: [Color] = revealing
            ? [inside, inside, outside, outside]
            : [outside, outside, inside, inside]
        return LinearGradient(
            stops: [
                .init(color: colors[0], location: 0),
                .init(color: colors[1], location: leftStop),
                .init(color: colors[2], location: rightStop),
                .init(color: colors[3], location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
