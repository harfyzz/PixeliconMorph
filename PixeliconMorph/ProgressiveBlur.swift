import SwiftUI

extension View {
    /// Box blur whose radius ramps from 0 at `start` to `maxRadius` at `end`.
    /// Points are in the view's local coordinate space; the ramp direction is
    /// the vector from `start` to `end`, so it works in any orientation.
    ///
    /// Backed by ProgressiveBlur.metal (`progressiveBlur` stitchable function).
    func progressiveBlur(from start: CGPoint, to end: CGPoint, maxRadius: CGFloat) -> some View {
        layerEffect(
            ShaderLibrary.progressiveBlur(
                .float2(Float(start.x), Float(start.y)),
                .float2(Float(end.x), Float(end.y)),
                .float(Float(maxRadius))
            ),
            maxSampleOffset: CGSize(width: maxRadius, height: maxRadius)
        )
    }
}
