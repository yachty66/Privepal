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
                                .foregroundStyle(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextField("", text: $messageText, axis: .vertical)
                            .foregroundStyle(.white)
                            .padding(.top, 8)
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
                                .frame(width: 36, height: 36)
                                .background(Color.gray.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        // Search Pill
                        Button(action: {}) {
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .font(.system(size: 14))
                                Text("Search")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.5))
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        // Mic Button
                        Button(action: {}) {
                            Image(systemName: "mic")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.gray.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(16)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}

