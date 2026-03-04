//
//  BrewSplashScreenView.swift
//  Instool
//
//  Created by Rodrigue de Guerre on 02/03/2026.
//

import SwiftUI


private extension Color {
    static let amber       = Color(red: 0.97, green: 0.62, blue: 0.11)
    static let amberLight  = Color(red: 1.00, green: 0.82, blue: 0.38)
    static let amberDark   = Color(red: 0.72, green: 0.36, blue: 0.04)
    static let amberGlow   = Color(red: 0.97, green: 0.62, blue: 0.11)
    static let canvas      = Color(red: 0.055, green: 0.055, blue: 0.075)
    static let glassTint   = Color(red: 0.85, green: 0.92, blue: 1.00)
    static let foam        = Color(red: 0.97, green: 0.96, blue: 0.92)
}


/// The outer profile of the mug body — widest at top, gentle taper.
struct MugBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: w, y: 0))
        p.addLine(to: CGPoint(x: w * 0.90, y: h * 0.92))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.10, y: h * 0.92),
            control: CGPoint(x: w * 0.50, y: h * 1.01)
        )
        p.closeSubpath()
        return p
    }
}

/// The handle — a D-ring on the right side, drawn as a stroked arc.
struct MugHandlePath: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        // Attach at 25 % and 68 % down the right edge
        let topAttach    = CGPoint(x: w * 0.90, y: h * 0.25)
        let bottomAttach = CGPoint(x: w * 0.90, y: h * 0.68)
        let controlX     = w * 0.90 + w * 0.60   // how far right the handle bows out

        var p = Path()
        p.move(to: topAttach)
        p.addCurve(
            to: bottomAttach,
            control1: CGPoint(x: controlX, y: topAttach.y + 4),
            control2: CGPoint(x: controlX, y: bottomAttach.y - 4)
        )
        return p
    }
}

/// Liquid fill inside the mug.
struct MugLiquidShape: Shape {
    var fillFraction: Double

    var animatableData: Double {
        get { fillFraction }
        set { fillFraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let glassH  = h * 0.92
        let liquidH = glassH * fillFraction
        let topY    = glassH - liquidH

        let t      = topY / glassH
        let leftX  = CGFloat(w * 0.10 * t)
        let rightX = w - CGFloat(w * 0.10 * t)

        var p = Path()
        p.move(to: CGPoint(x: leftX, y: topY))
        p.addCurve(
            to: CGPoint(x: rightX, y: topY),
            control1: CGPoint(x: leftX  + (rightX - leftX) * 0.33, y: topY - 5),
            control2: CGPoint(x: leftX  + (rightX - leftX) * 0.67, y: topY + 5)
        )
        p.addLine(to: CGPoint(x: w * 0.90, y: glassH))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.10, y: glassH),
            control: CGPoint(x: w * 0.50, y: glassH + h * 0.09)
        )
        p.closeSubpath()
        return p
    }
}

struct FoamWaveShape: Shape {
    var fillFraction: Double
    var wavePhase: Double          // 0…1, drives the ripple

    var animatableData: AnimatablePair<Double, Double> {
        get { .init(fillFraction, wavePhase) }
        set { fillFraction = newValue.first; wavePhase = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let glassH    = h * 0.92
        let liquidH   = glassH * fillFraction
        let baseY     = glassH - liquidH
        guard liquidH > 2 else { return Path() }

        let t      = baseY / glassH
        let leftX  = CGFloat(w * 0.10 * t)
        let rightX = w - CGFloat(w * 0.10 * t)
        let innerW = rightX - leftX
        let foamH: CGFloat = 10

        var p = Path()
        let segments = 8
        let segW = innerW / CGFloat(segments)

        p.move(to: CGPoint(x: leftX, y: baseY + foamH))

        for i in 0...segments {
            let x    = leftX + CGFloat(i) * segW
            let norm = Double(i) / Double(segments)
            let phase = (norm + wavePhase) * 2 * .pi
            let yOff = CGFloat(sin(phase)) * 2.5
            let cPhase = (norm + wavePhase + 0.5 / Double(segments)) * 2 * .pi
            if i < segments {
                let cx   = x + segW * 0.5
                let cyOff = CGFloat(sin(cPhase)) * 2.5
                p.addQuadCurve(
                    to: CGPoint(x: leftX + CGFloat(i + 1) * segW,
                                y: baseY + yOff),
                    control: CGPoint(x: cx, y: baseY + cyOff - 2)
                )
            }
        }

        // Close the foam blob downward
        let endX = leftX + innerW
        p.addLine(to: CGPoint(x: endX,  y: baseY + foamH))
        p.addQuadCurve(
            to: CGPoint(x: leftX, y: baseY + foamH),
            control: CGPoint(x: leftX + innerW * 0.5, y: baseY + foamH + 3)
        )
        p.closeSubpath()
        return p
    }
}

struct RisingBubble: Identifiable {
    let id    = UUID()
    var x:      CGFloat
    var size:   CGFloat
    var speed:  Double
    var delay:  Double
    var wobble: CGFloat
}

struct BubbleView: View {
    let bubble:       RisingBubble
    let glassHeight:  CGFloat
    let fillFraction: Double

    @State private var progress: Double = 0

    var body: some View {
        let startY   = glassHeight * 0.90
        let endY     = glassHeight * (1 - fillFraction) + 6
        let currentY = startY - (startY - endY) * progress
        let wobbleX  = CGFloat(sin(progress * .pi * 5)) * bubble.wobble

        Circle()
            .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
            .background(Circle().fill(Color.white.opacity(0.04)))
            .frame(width: bubble.size, height: bubble.size)
            .offset(x: bubble.x + wobbleX, y: currentY)
            .opacity(progress < 0.85 ? 0.9 : 0)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + bubble.delay) {
                    withAnimation(.linear(duration: bubble.speed).repeatForever(autoreverses: false)) {
                        progress = 1
                    }
                }
            }
    }
}

/// A diagonal glare stripe that sweeps across the glass body periodically.
struct ShimmerView: View {
    @State private var offset: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.14),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: w * 0.35)
                .rotationEffect(.degrees(15))
                .offset(x: offset * (w + w * 0.35))
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.6)
                        .delay(1.2)
                        .repeatForever(autoreverses: false)
                    ) {
                        offset = 1.4
                    }
                }
        }
        .clipped()
    }
}

struct BrewProgressBar: View {
    let progress: Double
    private let tickCount = 20
    private let amber = Color.amber

    var body: some View {
        VStack(spacing: 5) {
            // Segmented ticks
            HStack(spacing: 3) {
                ForEach(0..<tickCount, id: \.self) { i in
                    let threshold = Double(i + 1) / Double(tickCount)
                    let filled    = progress >= threshold - 0.001

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(filled
                              ? LinearGradient(colors: [.amberLight, .amber],
                                               startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [Color.white.opacity(0.07),
                                                        Color.white.opacity(0.07)],
                                               startPoint: .leading, endPoint: .trailing))
                        .frame(width: 10, height: 4)
                        .animation(.easeOut(duration: 0.25).delay(Double(i) * 0.02),
                                   value: progress)
                }
            }

            // Percentage label
            HStack {
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(amber.opacity(0.55))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                Spacer()
                Text("Homebrew")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.15))
            }
        }
        .frame(width: 246)
    }
}

// MARK: - Main Splash View
struct BrewSplashScreenView: View {
    let phase: LoadingPhase

    enum LoadingPhase: Equatable {
        case startingUp
        case loadingData
        case startingShell

        var message: String {
            switch self {
            case .startingUp:    return "Starting up…"
            case .loadingData:   return "Loading your data…"
            case .startingShell: return "Starting brew session…"
            }
        }

        var detail: String {
            switch self {
            case .startingUp:    return "Initializing"
            case .loadingData:   return "Reading formulae & casks"
            case .startingShell: return "Connecting to Homebrew"
            }
        }

        var progress: Double {
            switch self {
            case .startingUp:    return 0.20
            case .loadingData:   return 0.55
            case .startingShell: return 0.85
            }
        }
    }

    @State private var glassAppeared  = false
    @State private var displayedFill: Double = 0
    @State private var foamOpacity: Double   = 0
    @State private var wavePhase: Double     = 0
    @State private var dotPhase: Double      = 0
    @State private var glowPulse: Double     = 0

    private let glassW: CGFloat = 88
    private let glassH: CGFloat = 118

    private let bubbles: [RisingBubble] = (0..<14).map { _ in
        RisingBubble(
            x:      .random(in: -30...30),
            size:   .random(in: 2.5...6.5),
            speed:  .random(in: 1.6...3.2),
            delay:  .random(in: 0...2.5),
            wobble: .random(in: 2...6)
        )
    }

    var body: some View {
        ZStack {
            // Subtle ambient glow that pulses
            RadialGradient(
                colors: [
                    Color.amberGlow.opacity(0.06 + glowPulse * 0.04),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.38),
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack(alignment: .center) {

                    // Drop shadow glow
                    Ellipse()
                        .fill(Color.amberGlow.opacity(0.18 + glowPulse * 0.08))
                        .frame(width: glassW * 1.1, height: 14)
                        .blur(radius: 10)
                        .offset(y: glassH * 0.52)

                    // Liquid
                    MugLiquidShape(fillFraction: displayedFill)
                        .fill(
                            LinearGradient(
                                colors: [.amberLight, .amber, .amberDark],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: glassW, height: glassH)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                            .blendMode(.overlay)
                        )
                        .clipShape(MugBodyShape())
                        .animation(.spring(response: 1.0, dampingFraction: 0.72), value: displayedFill)

                    // Animated foam wave
                    FoamWaveShape(fillFraction: displayedFill, wavePhase: wavePhase)
                        .fill(Color.foam.opacity(0.90))
                        .frame(width: glassW, height: glassH)
                        .clipShape(MugBodyShape())
                        .opacity(foamOpacity)
                        .animation(.spring(response: 1.0, dampingFraction: 0.72), value: displayedFill)

                    // Rising bubbles
                    ZStack {
                        ForEach(bubbles) { bubble in
                            BubbleView(
                                bubble: bubble,
                                glassHeight: glassH * 0.92,
                                fillFraction: displayedFill
                            )
                        }
                    }
                    .frame(width: glassW, height: glassH)
                    .clipShape(MugBodyShape())
                    .opacity(displayedFill > 0.06 ? 1 : 0)

                    // Shimmer sweep
                    ShimmerView()
                        .frame(width: glassW, height: glassH)
                        .clipShape(MugBodyShape())

                    // Glass body outline
                    MugBodyShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.glassTint.opacity(0.22),
                                    Color.glassTint.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                        .frame(width: glassW, height: glassH)

                    // Handle
                    MugHandlePath()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.glassTint.opacity(0.20),
                                    Color.glassTint.opacity(0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: glassW, height: glassH)

                    // Left glare stripe
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.10), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 7, height: glassH * 0.52)
                        .offset(x: -glassW * 0.34, y: -glassH * 0.12)
                        .allowsHitTesting(false)
                }
                .frame(width: glassW + 40, height: glassH + 20)  // extra room for handle & shadow
                .opacity(glassAppeared ? 1 : 0)
                .scaleEffect(glassAppeared ? 1 : 0.80)
                .animation(.spring(response: 0.60, dampingFraction: 0.68).delay(0.08), value: glassAppeared)

                Spacer().frame(height: 30)

                VStack(spacing: 5) {
                    Text("Støre")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.amberLight, .amber],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .tracking(1)

                    Text("The missing UI for Homebrew")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.28))
                        .tracking(2.5)
                }

                Spacer().frame(height: 28)

                VStack(spacing: 7) {
                    Text(phase.message)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.amber)
                        .id("msg-\(phase.message)")
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 6)),
                            removal:   .opacity.combined(with: .offset(y: -6))
                        ))
                        .animation(.easeInOut(duration: 0.28), value: phase.message)

                    HStack(spacing: 4) {
                        Text(phase.detail)
                            .id("det-\(phase.detail)")
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.22), value: phase.detail)
                        AnimatedDotsView(phase: dotPhase)
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.28))
                }
                .opacity(glassAppeared ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.35), value: glassAppeared)

                Spacer().frame(height: 24)

                BrewProgressBar(progress: phase.progress)
                    .opacity(glassAppeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.45), value: glassAppeared)

                Spacer()
            }
        }
        .onAppear { runAppearAnimations() }
        .onChange(of: phase) { _, new in
            withAnimation(.spring(response: 0.75, dampingFraction: 0.78)) {
                displayedFill = new.progress
            }
        }
    }

    private func runAppearAnimations() {
        glassAppeared = true

        withAnimation(.spring(response: 1.0, dampingFraction: 0.75).delay(0.20)) {
            displayedFill = phase.progress
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.65)) {
            foamOpacity = 1
        }
        // Foam wave continuous oscillation
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
            wavePhase = 1.0
        }
        // Glow pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowPulse = 1.0
        }
        // Dot animation
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            dotPhase = 1.0
        }
    }
}

private struct AnimatedDotsView: View {
    let phase: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                let delay = Double(i) / 3.0
                let t     = (phase + delay).truncatingRemainder(dividingBy: 1.0)
                let alpha = sin(t * .pi)
                Circle()
                    .frame(width: 3, height: 3)
                    .opacity(max(0.12, alpha))
            }
        }
    }
}

struct BrewLoadingOverlay: View {
    @Environment(HomeBrewVM.self) private var viewModel

    private var phase: BrewSplashScreenView.LoadingPhase? {
        if viewModel.isStartingUp    { return .startingUp }
        if viewModel.isLoading       { return .loadingData }
        if viewModel.isShellStarting { return .startingShell }
        return nil
    }

    var body: some View {
        if let phase {
            BrewSplashScreenView(phase: phase)
                .transition(.opacity)
                .animation(.easeOut(duration: 0.4), value: phase)
        }
    }
}


#Preview("Starting Up") {
    BrewSplashScreenView(phase: .startingUp)
        .frame(width: 420, height: 560)
}

#Preview("Loading Data") {
    BrewSplashScreenView(phase: .loadingData)
        .frame(width: 420, height: 560)
}

#Preview("Starting Shell") {
    BrewSplashScreenView(phase: .startingShell)
        .frame(width: 420, height: 560)
}
