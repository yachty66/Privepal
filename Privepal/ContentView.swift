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
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
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
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
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
                .padding(.bottom, 100) // Push it up a bit
                
                Spacer()
                
                // Bottom Input Bar
                VStack(alignment: .leading, spacing: 12) {
                    // Text Input Area
                    ZStack(alignment: .topLeading) {
                        if messageText.isEmpty {
                            Text("Message")
                                .font(.system(size: 18))
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.top, 12)
                                .padding(.leading, 6)
                        }
                        TextField("", text: $messageText, axis: .vertical)
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                            .padding(.top, 12)
                            .padding(.leading, 6)
                    }
                    .frame(minHeight: 48)
                    
                    // Tools Row
                    HStack(spacing: 12) {
                        // Plus Button
                        Button(action: {}) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }
                        
                        // Search Pill
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "globe")
                                    .font(.system(size: 18))
                                Text("Search")
                                    .font(.system(size: 16))
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .glassEffect(.regular.interactive(), in: .capsule)
                        }
                        
                        Spacer()
                        
                        // Mic Button
                        Button(action: {}) {
                            Image(systemName: "mic")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }
                    }
                }
                .padding(16)
                .glassEffect(in: .rect(cornerRadius: 36))
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}

