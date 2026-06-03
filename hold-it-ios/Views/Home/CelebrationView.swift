//
//  CelebrationView.swift
//  hold-it-ios
//

import SwiftUI

struct CelebrationView: View {
    @State private var particles: [Particle] = []
    @Binding var isActive: Bool

    private let emojis = ["🎉", "✨", "🎊", "💪", "🔥", "🌟", "❤️", "👏"]
    private let totalParticles = 50

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ParticleView(particle: particle)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            spawnParticles()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                isActive = false
            }
        }
    }

    private func spawnParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for i in 0..<totalParticles {
            let delay = Double.random(in: 0...0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let isLogo = i < 20 // 前3个是 AppLogo
                let particle = Particle(
                    id: i,
                    content: isLogo ? .logo : .emoji(emojis.randomElement()!),
                    startX: CGFloat.random(in: screenWidth * 0.2...screenWidth * 0.8),
                    endX: CGFloat.random(in: screenWidth * 0.1...screenWidth * 0.9),
                    startY: screenHeight + 40,
                    endY: CGFloat.random(in: screenHeight * 0.1...screenHeight * 0.5),
                    rotation: Double.random(in: -30...30),
                    scale: isLogo ? CGFloat.random(in: 0.6...0.9) : CGFloat.random(in: 0.8...1.4),
                    duration: Double.random(in: 0.8...1.2)
                )
                particles.append(particle)
            }
        }
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
    let id: Int
    let content: ParticleContent
    let startX: CGFloat
    let endX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let rotation: Double
    let scale: CGFloat
    let duration: Double
}

enum ParticleContent: Equatable {
    case emoji(String)
    case logo
}

// MARK: - Particle View
struct ParticleView: View {
    let particle: Particle
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.01
    @State private var opacity: Double = 1

    var body: some View {
        contentView
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                // 初始位置
                offset = CGSize(width: particle.startX - UIScreen.main.bounds.width / 2,
                                height: particle.startY - UIScreen.main.bounds.height / 2)

                withAnimation(.easeOut(duration: particle.duration)) {
                    offset = CGSize(width: particle.endX - UIScreen.main.bounds.width / 2,
                                    height: particle.endY - UIScreen.main.bounds.height / 2)
                    scale = particle.scale
                    rotation = particle.rotation
                }

                // 上浮后缓慢下落 + 淡出
                DispatchQueue.main.asyncAfter(deadline: .now() + particle.duration) {
                    withAnimation(.easeIn(duration: 1.0)) {
                        offset = CGSize(
                            width: particle.endX - UIScreen.main.bounds.width / 2 + CGFloat.random(in: -30...30),
                            height: (particle.endY - UIScreen.main.bounds.height / 2) + 120
                        )
                        rotation = particle.rotation + Double.random(in: 15...45)
                        opacity = 0
                    }
                }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        switch particle.content {
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: 36))
        case .logo:
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }
}
