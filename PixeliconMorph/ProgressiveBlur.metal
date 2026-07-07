#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Box blur whose radius ramps from 0 at `start` to `maxRadius` at `end`.
// The ramp is the projection of the fragment position onto the start→end line,
// so any direction works (vertical, horizontal, diagonal). Positions are in
// the layer's local pixel space.
[[ stitchable ]] half4 progressiveBlur(
    float2 position,
    SwiftUI::Layer layer,
    float2 start,
    float2 end,
    float maxRadius
) {
    float2 dir = end - start;
    float len2 = dot(dir, dir);
    float t = len2 > 0.0 ? clamp(dot(position - start, dir) / len2, 0.0, 1.0) : 0.0;
    float radius = maxRadius * t;

    if (radius < 0.5) {
        return layer.sample(position);
    }

    // 9x9 = 81 taps, spaced by radius. Good enough for a demo; swap for a
    // separable Gaussian if you need real quality.
    const int TAPS = 4;
    half4 sum = half4(0);
    float count = 0;
    for (int y = -TAPS; y <= TAPS; y++) {
        for (int x = -TAPS; x <= TAPS; x++) {
            float2 offset = float2(x, y) * (radius / float(TAPS));
            sum += layer.sample(position + offset);
            count += 1.0;
        }
    }
    return sum / half(count);
}
