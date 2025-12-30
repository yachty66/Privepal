//
//  ContentView.swift
//  Privepal
//
//  Created by Max Hager on 12/29/25.
//

import SwiftUI

struct ContentView: View {
    @State private var messageText: String = ""
    @FocusState private var isFocused: Bool
    
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
            
            // Disclaimer Text (Pinned, always visible)
            Text("AI models can make mistakes. Always check\nimportant info.")
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.bottom, 20)
            
            // Scrollable Content Area (Enables swipe dismissal)
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer()
                            
                        // Center glowing orb/dots
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
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    isFocused = false
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Bottom Input Bar
            VStack(alignment: .leading, spacing: 10) {
                // Text Input Area
                ZStack(alignment: .topLeading) {
                    if messageText.isEmpty {
                        Text("Message")
                            .font(.system(size: 19))
                            .foregroundStyle(Color(white: 0.25))
                            .padding(.top, 4)
                            .padding(.leading, 4)
                            .onTapGesture {
                                isFocused = true
                            }
                    }
                    TextField("", text: $messageText, axis: .vertical)
                        .font(.system(size: 19))
                        .foregroundStyle(.white)
                        .padding(.top, 4)
                        .padding(.leading, 4)
                        .focused($isFocused)
                }
                .frame(minHeight: 36)
                
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
                    
                    // Mic Button or Send Button
                    if messageText.isEmpty {
                        Button(action: {}) {
                            Image(systemName: "mic")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
                        }
                    } else {
                        Button(action: {
                            // Send action
                            messageText = ""
                        }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(.white))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(12)
            .animation(.bouncy, value: messageText.isEmpty) // Animate the transition
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
            .padding(.bottom, 8) // Small bottom padding relative to safe area
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
