# Privepal - App Store Submission Roadmap

This document outlines the remaining tasks and requirements to launch **Privepal** on the Apple App Store.

## 🚀 Launch Checklist

### 1. Technical Preparation (Swift/Xcode)
- [ ] **Fix Deployment Target**: Update `IPHONEOS_DEPLOYMENT_TARGET` from `26.1` to `17.0` in `project.pbxproj`.
- [ ] **Privacy Manifest**: Create `PrivacyInfo.xcprivacy` to declare data usage.
- [ ] **API Keys Audit**: Ensure all production keys in `Secrets.swift` are valid.
- [ ] **App Icon Verification**: Confirm all required sizes (1024x1024, etc.) are in `AppIcon.appiconset`.

### 2. App Store Connect Requirements
- [ ] **Apple Developer Membership**: Ensure account is active ($99/yr).
- [ ] **App Record**: Create the app entry at [App Store Connect](https://appstoreconnect.apple.com/).
- [ ] **Privacy Policy**: Host a privacy policy at a public URL (Mandatory).
- [ ] **Support URL**: A basic website or contact page for users.

### 3. Marketing & Metadata
- [ ] **Screenshots**:
    - [ ] iPhone 6.7" (iPhone 15/14 Pro Max)
    - [ ] iPhone 5.5" (iPhone 8 Plus)
- [ ] **App Description**: Draft a compelling description highlighting privacy and AI features.
- [ ] **Keywords**: Optimize for "AI Chat", "Privacy", "Local LLM", etc.

### 4. Submission Flow
- [ ] **Archive & Validate**: Build the release archive in Xcode.
- [ ] **TestFlight**: Upload first build to TestFlight for internal testing.
- [ ] **App Review**: Submit for final Apple review.

---
*Last Updated: January 10, 2026*
