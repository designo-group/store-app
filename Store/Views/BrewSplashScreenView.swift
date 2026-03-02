//
//  BrewSplashScreenView.swift
//  Instool
//
//  Created by Rodrigue de Guerre on 02/03/2026.
//

import SwiftUI

// MARK: - Schooner Shape

/// A beer schooner outline: wider at top, slight taper, flat base.
struct SchoonerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Top rim corners
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: w, y: 0))
        // Sides taper inward slightly toward base
        p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.88))
        // Base curve
        p.addQuadCurve(
            to: CGPoint(x: w * 0.12, y: h * 0.88),
            control: CGPoint(x: w * 0.5, y: h * 0.96)
        )
        p.closeSubpath()
        return p
    }
}

/// Liquid fill inside the schooner — fills from bottom up to `fillFraction`.
struct SchoonerLiquidShape: Shape {
    var fillFraction: Double  // 0 = empty, 1 = full

    var animatableData: Double {
        get { fillFraction }
        set { fillFraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let glassH = h * 0.88               // glass inner height
        let liquidH = glassH * fillFraction
        let topY = glassH - liquidH         // top of liquid (Y from top)

        // Interpolate X at topY along the slanted sides
        // At y=0 (rim): x goes from 0 to w
        // At y=glassH (base inner): x goes from w*0.12 to w*0.88
        let leftX  = 0       + (w * 0.12) * (topY / glassH)
        let rightX = w       - (w * 0.12) * (topY / glassH)

        var p = Path()
        // Wave at the top of liquid
        p.move(to: CGPoint(x: leftX, y: topY))
        p.addCurve(
            to: CGPoint(x: rightX, y: topY),
            control1: CGPoint(x: leftX + (rightX - leftX) * 0.35, y: topY - 4),
            control2: CGPoint(x: leftX + (rightX - leftX) * 0.65, y: topY + 4)
        )
        // Down the right side to base
        p.addLine(to: CGPoint(x: w * 0.88, y: glassH))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.12, y: glassH),
            control: CGPoint(x: w * 0.5, y: glassH + h * 0.08)
        )
        p.closeSubpath()
        return p
    }
}

/// Foam bubbles at the surface
struct FoamShape: Shape {
    var fillFraction: Double
    var animatableData: Double {
        get { fillFraction }
        set { fillFraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let glassH = h * 0.88
        let liquidH = glassH * fillFraction
        let topY = glassH - liquidH

        let leftX  = CGFloat(w * 0.12 * (topY / glassH))
        let innerW = w - 2 * leftX
        guard innerW > 4 else { return Path() }

        var p = Path()
        let bubbleR: CGFloat = 5
        var x = leftX + bubbleR
        var toggle = false
        while x < leftX + innerW - bubbleR {
            let y = topY - bubbleR + (toggle ? 2 : -1)
            p.addEllipse(in: CGRect(x: x - bubbleR, y: y - bubbleR,
                                    width: bubbleR * 2, height: bubbleR * 1.4))
            x += bubbleR * 1.6
            toggle.toggle()
        }
        return p
    }
}

// MARK: - Rising Bubble

struct RisingBubble: Identifiable {
    let id = UUID()
    var x: CGFloat
    var size: CGFloat
    var speed: Double
    var delay: Double
    var wobble: CGFloat
}

struct BubbleView: View {
    let bubble: RisingBubble
    let glassHeight: CGFloat
    let fillFraction: Double

    @State private var progress: Double = 0

    var body: some View {
        let startY = glassHeight * 0.85
        let endY   = glassHeight * (1 - fillFraction) + 4
        let currentY = startY - (startY - endY) * progress
        let wobbleX = sin(progress * .pi * 4) * bubble.wobble

        Circle()
            .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
            .background(Circle().fill(Color.white.opacity(0.06)))
            .frame(width: bubble.size, height: bubble.size)
            .offset(x: bubble.x + wobbleX, y: currentY)
            .opacity(progress < 0.9 ? 1 : 0)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + bubble.delay) {
                    withAnimation(.linear(duration: bubble.speed).repeatForever(autoreverses: false)) {
                        progress = 1
                    }
                }
            }
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

    // MARK: - State

    @State private var appeared        = false
    @State private var displayedFill: Double = 0
    @State private var foamOpacity: Double = 0
    @State private var waveOffset: CGFloat = 0
    @State private var shimmerPhase: CGFloat = 0
    @State private var dotPhase: Double = 0

    private let glassW: CGFloat = 80
    private let glassH: CGFloat = 110

    private let bubbles: [RisingBubble] = (0..<12).map { _ in
        RisingBubble(
            x: CGFloat.random(in: -28...28),
            size: CGFloat.random(in: 3...7),
            speed: Double.random(in: 1.8...3.5),
            delay: Double.random(in: 0...2.0),
            wobble: CGFloat.random(in: 2...6)
        )
    }

    // Amber beer color
    private let amber = Color(red: 0.97, green: 0.62, blue: 0.11)
    private let amberLight = Color(red: 1.0, green: 0.78, blue: 0.30)
    private let amberDark = Color(red: 0.75, green: 0.40, blue: 0.05)
    private let bg = Color(red: 0.07, green: 0.07, blue: 0.09)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            // Background glow
            RadialGradient(
                colors: [amber.opacity(0.07), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Schooner Glass
                ZStack {
                    // Glass body (stroke)
                    SchoonerShape()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: glassW, height: glassH)

                    // Liquid fill (clipped to glass shape)
                    SchoonerLiquidShape(fillFraction: displayedFill)
                        .fill(
                            LinearGradient(
                                colors: [amberLight, amber, amberDark],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: glassW, height: glassH)
                        // Inner shimmer stripe
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .blendMode(.overlay)
                        )
                        .clipShape(SchoonerShape())
                        .animation(.spring(response: 0.9, dampingFraction: 0.75), value: displayedFill)

                    // Foam
                    FoamShape(fillFraction: displayedFill)
                        .fill(Color.white.opacity(0.85))
                        .frame(width: glassW, height: glassH)
                        .clipShape(SchoonerShape())
                        .opacity(foamOpacity)
                        .animation(.spring(response: 0.9, dampingFraction: 0.75), value: displayedFill)

                    // Rising bubbles (clipped)
                    ZStack {
                        ForEach(bubbles) { bubble in
                            BubbleView(
                                bubble: bubble,
                                glassHeight: glassH * 0.88,
                                fillFraction: displayedFill
                            )
                        }
                    }
                    .frame(width: glassW, height: glassH)
                    .clipShape(SchoonerShape())
                    .opacity(displayedFill > 0.05 ? 1 : 0)

                    // Glass glare
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 10, height: glassH * 0.55)
                        .offset(x: -glassW * 0.35, y: -glassH * 0.1)
//                        .clipShape(SchoonerShape().offset(x: glassW * 0.35, y: glassH * 0.1) as! SchoonerShape) // approximate
                }
                .frame(width: glassW, height: glassH)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.75)
                .shadow(color: amber.opacity(0.25), radius: 24, y: 8)

                Spacer().frame(height: 32)

                // MARK: Title
                VStack(spacing: 4) {
                    Text("Støre")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [amberLight, amber],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("The missing UI for the missing Package Manager (Homebrew)")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.30))
                        .kerning(1.5)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                Spacer().frame(height: 28)

                // MARK: Phase message
                VStack(spacing: 6) {
                    Text(phase.message)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(amber)
                        .id(phase.message)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 5)),
                            removal:   .opacity.combined(with: .offset(y: -5))
                        ))
                        .animation(.easeInOut(duration: 0.3), value: phase.message)

                    HStack(spacing: 3) {
                        Text(phase.detail)
                            .id(phase.detail)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.25), value: phase.detail)

                        AnimatedDotsView(phase: dotPhase)
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.30))
                }
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 28)

                // MARK: Fill level label
                Text(String(format: "%.0f%%", phase.progress * 100))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(amber.opacity(0.45))
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: phase.progress)

                Spacer()

                Text("Powered by Homebrew")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.12))
                    .padding(.bottom, 20)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear { runAppearAnimations() }
        .onChange(of: phase) { _, new in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                displayedFill = new.progress
            }
        }
    }

    // MARK: - Appear

    private func runAppearAnimations() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.1)) {
            appeared = true
        }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.25)) {
            displayedFill = phase.progress
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.6)) {
            foamOpacity = 1
        }
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            dotPhase = 1.0
        }
    }
}

// MARK: - Animated Dots

private struct AnimatedDotsView: View {
    let phase: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                let delay = Double(i) / 3.0
                let t = (phase + delay).truncatingRemainder(dividingBy: 1.0)
                let opacity = sin(t * .pi)
                Circle()
                    .frame(width: 3, height: 3)
                    .opacity(max(0.15, opacity))
            }
        }
    }
}

// MARK: - Integration

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

// MARK: - Preview

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
