import SwiftUI

/// Presses the button label down slightly and springs back on release.
/// Cheap tactile feedback for any custom button — apply with `.buttonStyle(...)`.
struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.94
    var animation: Animation = .spring(response: 0.2, dampingFraction: 0.6)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(animation, value: configuration.isPressed)
    }
}
