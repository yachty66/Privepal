import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var iCloudSyncEnabled = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Description
                        Text("Privepal is a client for chatting with open source AI\nand self-hosted LLMs.")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal)
                        
                        // Configure Section
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Configure")
                            
                            VStack(spacing: 0) {
                                SettingsRow(icon: "sparkles", title: "AI Providers")
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                                SettingsRow(icon: "bubble.left.and.bubble.right", title: "System Message")
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                                SettingsRow(icon: "waveform", title: "Voice & Speech")
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                                SettingsRow(icon: "bell", title: "Sounds")
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                                SettingsRow(icon: "command", title: "On Launch")
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                                SettingsRow(icon: "paintpalette", title: "Theme")
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                                ToggleRow(icon: "icloud", title: "iCloud Sync", isOn: $iCloudSyncEnabled)
                            }
                            .background(Color(white: 0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal)
                        
                        // Permissions Section
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Permissions")
                            
                            VStack(spacing: 0) {
                                CheckmarkRow(icon: "mic.fill", title: "Microphone", isGranted: true)
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 50)
                                CheckmarkRow(icon: "location.fill", title: "Location (Experimental)", isGranted: true)
                            }
                            .background(Color(white: 0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Privepal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.15))
                    .clipShape(Capsule())
                }
            }
            .background(Color.black)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Helper Views

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 14))
            .foregroundStyle(.gray)
            .padding(.leading, 8)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 28, height: 28)
                    .background(Color(white: 0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(.white)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.gray)
            }
            .padding()
        }
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 28, height: 28)
                .background(Color(white: 0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(.white)
            
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.white)
        }
        .padding()
    }
}

struct CheckmarkRow: View {
    let icon: String
    let title: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 28, height: 28)
                .background(Color(white: 0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(.white)
            
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.white)
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
