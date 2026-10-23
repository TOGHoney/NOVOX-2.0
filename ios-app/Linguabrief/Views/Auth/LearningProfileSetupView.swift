import SwiftUI

/// Onboarding wizard for selecting target language and CEFR proficiency.
/// Replicates `src/pages/LearningProfile.jsx`.
public struct LearningProfileSetupView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    
    @State private var currentStep: Int = 1
    @State private var selectedLanguage: String = "Spanish"
    @State private var selectedLevel: String = "B1"
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // Step Progress Header
                HStack(spacing: 8) {
                    Circle()
                        .fill(currentStep >= 1 ? Constants.Colors.brandBurgundy : Color(.systemGray4))
                        .frame(width: 28, height: 28)
                        .overlay(Text("1").font(.caption.bold()).foregroundColor(.white))
                    
                    Rectangle()
                        .fill(currentStep == 2 ? Constants.Colors.brandBurgundy : Color(.systemGray4))
                        .frame(height: 3)
                    
                    Circle()
                        .fill(currentStep == 2 ? Constants.Colors.brandBurgundy : Color(.systemGray4))
                        .frame(width: 28, height: 28)
                        .overlay(Text("2").font(.caption.bold()).foregroundColor(.white))
                }
                .padding(.horizontal, 40)
                .padding(.top, 16)
                
                // Visible Error Banner
                if let error = authVM.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                if currentStep == 1 {
                    // Step 1: Language Selection
                    VStack(spacing: 12) {
                        Text("What language do you want to learn?")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("All articles and vocabulary intelligence will adapt to this choice.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(Constants.targetLanguages) { lang in
                                    let isSelected = selectedLanguage == lang.name
                                    Button(action: {
                                        selectedLanguage = lang.name
                                        withAnimation {
                                            currentStep = 2
                                        }
                                    }) {
                                        HStack(spacing: 16) {
                                            Text(lang.flag)
                                                .font(.system(size: 32))
                                            Text(lang.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Constants.Colors.brandBurgundy)
                                                    .font(.title3)
                                            }
                                        }
                                        .padding()
                                        .cardStyle(backgroundColor: isSelected ? Constants.Colors.brandBurgundy.opacity(0.08) : Color(.secondarySystemBackground))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                    }
                } else {
                    // Step 2: CEFR Level Selection
                    VStack(spacing: 12) {
                        Text("What is your current proficiency?")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("Choose your CEFR level to calibrate reading difficulty.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(Constants.cefrLevels) { cefr in
                                    let isSelected = selectedLevel == cefr.code
                                    Button(action: {
                                        selectedLevel = cefr.code
                                    }) {
                                        HStack(alignment: .top, spacing: 14) {
                                            CEFRBadge(cefr.code)
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(cefr.title)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Text(cefr.description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Constants.Colors.brandBurgundy)
                                                    .font(.title3)
                                            }
                                        }
                                        .padding()
                                        .cardStyle(backgroundColor: isSelected ? Constants.Colors.brandBurgundy.opacity(0.08) : Color(.secondarySystemBackground))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                        
                        HStack(spacing: 12) {
                            Button("Back") {
                                withAnimation { currentStep = 1 }
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                            .frame(width: 80)
                            
                            Button(action: {
                                guard !selectedLanguage.isEmpty else {
                                    authVM.errorMessage = "Please choose a target language."
                                    withAnimation { currentStep = 1 }
                                    return
                                }
                                guard !selectedLevel.isEmpty else {
                                    authVM.errorMessage = "Please choose a CEFR proficiency level."
                                    return
                                }
                                Task {
                                    _ = await authVM.updateLearningProfile(
                                        targetLanguage: selectedLanguage,
                                        cefrLevel: selectedLevel
                                    )
                                }
                            }) {
                                if authVM.isLoading {
                                    ProgressView().tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                } else {
                                    Text("Complete Setup")
                                        .burgundyButtonStyle()
                                }
                            }
                            .disabled(authVM.isLoading)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                authVM.errorMessage = nil
            }
        }
    }
}
