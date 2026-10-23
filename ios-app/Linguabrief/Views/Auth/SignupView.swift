import SwiftUI

/// User registration view replicating `src/pages/Signup.jsx`.
public struct SignupView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Header
                VStack(spacing: 8) {
                    Text("NOVOX")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(Constants.Colors.brandBurgundy)
                        .tracking(2)
                    
                    Text("Create your learning account")
                        .font(.headline)
                    
                    Text("Read authentic world news in the language you want to master.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Form Card
                VStack(alignment: .leading, spacing: 18) {
                    if let error = authVM.errorMessage {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            if error.contains("already in use") {
                                Button("Already have an account? Sign in now") {
                                    dismiss()
                                }
                                .font(.caption.bold())
                                .foregroundColor(Constants.Colors.brandBurgundy)
                                .padding(.top, 2)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        TextField("Choose a username (min 3 chars)", text: $username)
                            .font(.subheadline)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email Address")
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
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        SecureField("Choose a password (min 6 chars)", text: $password)
                            .font(.subheadline)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        Task {
                            _ = await authVM.signup(username: username, email: email, password: password)
                        }
                    }) {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        } else {
                            Text("Create Account")
                                .burgundyButtonStyle()
                        }
                    }
                    .disabled(authVM.isLoading)
                }
                .padding(24)
                .cardStyle()
                .padding(.horizontal)
                
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Sign in") {
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(Constants.Colors.brandBurgundy)
                }
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
