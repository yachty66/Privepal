//
//  ContentView.swift
//  Privepal
//
//  Created by Max Hager on 12/29/25.
//

import SwiftUI

struct ContentView: View {
    @State private var messageText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20)) // Slightly smaller icon
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("Anthropic: Claude 3...")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            Spacer()
            
            // Center Content
            VStack(spacing: 20) {
                Text("AI models can make mistakes. Always check\nimportant info.")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    
                // Placeholder for the center glowing orb/dots
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.2), .clear],
                                center: .center,
                                    startRadius: 5,
                                    endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        
                    Image(systemName: "circle.dotted") // Approximating the dot pattern
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.white.opacity(0.1))
                }
            }
            .padding(.bottom, 40) // Reduced static padding since Spacer handles it
            
            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            // Bottom Input Bar
            VStack(alignment: .leading, spacing: 12) {
                // Text Input Area
                ZStack(alignment: .topLeading) {
                    if messageText.isEmpty {
                        Text("Message")
                            .font(.system(size: 19))
                            .foregroundStyle(Color(white: 0.25))
                            .padding(.top, 4)
                            .padding(.leading, 4)
                    }
                    TextField("", text: $messageText, axis: .vertical)
                        .font(.system(size: 19))
                        .foregroundStyle(.white)
                        .padding(.top, 4)
                        .padding(.leading, 4)
                }
                .frame(minHeight: 40)
                
                // Tools Row
                HStack(spacing: 12) {
                    // Plus Button
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
                    }
                    
                    // Search Pill
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .font(.system(size: 17))
                            Text("Search")
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .capsule)
                    }
                    
                    Spacer()
                    
                    // Mic Button
                    Button(action: {}) {
                        Image(systemName: "mic")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
                    }
                }
            }
            .padding(16)
            .glassEffect(.regular.tint(.black.opacity(0.6)), in: .rect(cornerRadius: 38))
            .overlay(
                RoundedRectangle(cornerRadius: 38)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10) // Small bottom padding relative to safe area
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
