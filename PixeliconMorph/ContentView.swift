//
//  ContentView.swift
//  PixeliconMorph
//
//  Created by Afeez Yunus on 07/07/2026.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    @State var morphIcon = RiveViewModel(fileName: "pixelmorph", stateMachineName: "Main")
    @State private var inputText = ""

    var body: some View {
        ZStack {
            Color("bg").ignoresSafeArea()
            VStack {
                VStack(spacing:16){
                    morphIcon.view()
                        .frame(width: 80, height: 80)
                    Text("Start Creating or drop media...")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                Spacer()
                    .frame(height: 120)
                inputField
            }
        }
    }

    private var inputField: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .leading) {
                if inputText.isEmpty {
                    StaggeredText(text: "What would you like to create?")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                        .allowsHitTesting(false)
                }
                TextField("", text: $inputText)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .textFieldStyle(.plain)
            }

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
                        .progressiveBlur(from: CGPoint(x: 35, y: 0), to: CGPoint(x: 90, y: 0), maxRadius: 6)
                }

                Spacer()

                Image(systemName: "waveform")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 0.698, green: 0.698, blue: 0.698))

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 0.698, green: 0.698, blue: 0.698))
            }
        }
        .padding(12)
        .frame(width:350)
        .background(Color(red: 0.102, green: 0.102, blue: 0.102))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}

private struct StaggeredText: View {
    let text: String
    /// Duration of one shimmer sweep across the text.
    var shimmerDuration: Double = 1.5
    /// Rest time between sweeps — characters sit at full opacity.
    var pauseDuration: Double = 1.0
    /// Width of the shimmer wave, in characters.
    var wavelength: Double = 8.0
    /// Opacity at the wave's dip.
    var minOpacity: Double = 0.1

    var body: some View {
        let cycle = shimmerDuration + pauseDuration
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle)
            HStack(spacing: 0) {
                ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                    Text(String(char))
                        .opacity(opacity(at: index, t: t))
                }
            }
        }
    }

    private func opacity(at index: Int, t: Double) -> Double {
        guard t <= shimmerDuration else { return 1.0 }
        let travel = Double(text.count) + wavelength * 2
        let center = t / shimmerDuration * travel - wavelength
        let dist = Double(index) - center
        let sigma = wavelength / 2
        let bump = exp(-dist * dist / (2 * sigma * sigma))
        return 1.0 - (1.0 - minOpacity) * bump
    }
}

extension View {
    /// Box blur whose radius ramps from 0 at `start` to `maxRadius` at `end`.
    /// Points are in the view's local coordinate space; the ramp direction is
    /// the vector from `start` to `end`, so it works in any orientation.
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
