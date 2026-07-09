import SwiftUI

extension AnyTransition {
    /// Blurs and fades content on insertion/removal.
    static func blurFade(radius: CGFloat = 12) -> AnyTransition {
        .modifier(
            active: BlurEffectModifier(radius: radius, scale: 1, opacity: 0),
            identity: BlurEffectModifier(radius: 0, scale: 1, opacity: 1)
        )
    }

    /// Blurs, scales, and fades content on insertion/removal.
    static func blurScale(radius: CGFloat = 10, scale: CGFloat = 0.9) -> AnyTransition {
        .modifier(
            active: BlurEffectModifier(radius: radius, scale: scale, opacity: 0),
            identity: BlurEffectModifier(radius: 0, scale: 1, opacity: 1)
        )
    }

    static var blurFade: AnyTransition { blurFade() }
    static var blurScale: AnyTransition { blurScale() }
}

private struct BlurEffectModifier: ViewModifier {
    let radius: CGFloat
    let scale: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .blur(radius: radius)
            .opacity(opacity)
    }
}
