import SwiftUI

/// User login view replicating `src/pages/login.jsx`.
public struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignup: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Brand Header
                    VStack(spacing: 8) {
                        Text("NOVOX")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(Constants.Colors.brandBurgundy)
                            .tracking(2)
                        
                        Text("Linguabrief — Global News for Language Learners")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 12)
                    
                    // Card Container
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Welcome back")
                            .font(.title2.bold())
                        
                        if let error = authVM.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            TextField("you@example.com", text: $email)
                                .font(.subheadline)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            SecureField("Enter your password", text: $password)
                                .font(.subheadline)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            Task {
                                _ = await authVM.login(email: email, password: password)
                            }
                        }) {
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            } else {
                                Text("Sign In")
                                    .burgundyButtonStyle()
                            }
                        }
                        .disabled(authVM.isLoading)
                    }
                    .padding(24)
                    .cardStyle()
                    .padding(.horizontal)
                    
                    // Switch to Signup
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Create one") {
                            showSignup = true
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(Constants.Colors.brandBurgundy)
                    }
                    .padding(.top, 12)
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
            }
            .onAppear {
                authVM.errorMessage = nil
            }
        }
    }
}
