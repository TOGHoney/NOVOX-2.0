import SwiftUI

/// Threaded article discussion comments sheet.
public struct CommentsSheetView: View {
    @ObservedObject public var detailVM: ArticleDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var commentInput: String = ""
    @State private var replyToComment: Comment?
    
    public init(detailVM: ArticleDetailViewModel) {
        self.detailVM = detailVM
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Comments List
                if detailVM.isCommentsLoading && detailVM.comments.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading discussion...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if detailVM.comments.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No comments yet")
                            .font(.headline)
                        Text("Start the conversation by sharing your reaction to this article.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(detailVM.comments) { comment in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Circle()
                                        .fill(Constants.Colors.brandBurgundy.opacity(0.15))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Text(String(comment.author.prefix(1)).uppercased())
                                                .font(.caption.bold())
                                                .foregroundColor(Constants.Colors.brandBurgundy)
                                        )
                                    
                                    Text(comment.author)
                                        .font(.subheadline.bold())
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        replyToComment = comment
                                    }) {
                                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                
                                Text(comment.text)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 36)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
                
                // Reply indicator banner
                if let replying = replyToComment {
                    HStack {
                        Text("Replying to @\(replying.author)")
                            .font(.caption.bold())
                            .foregroundColor(Constants.Colors.brandBurgundy)
                        Spacer()
                        Button(action: { replyToComment = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                }
                
                // Bottom Input Bar
                HStack(spacing: 10) {
                    TextField("Add a comment...", text: $commentInput)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Button(action: {
                        Task {
                            let success = await detailVM.postComment(
                                text: commentInput,
                                parentId: replyToComment?.id
                            )
                            if success {
                                commentInput = ""
                                replyToComment = nil
                            }
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(commentInput.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : Constants.Colors.brandBurgundy)
                    }
                    .disabled(commentInput.trimmingCharacters(in: .whitespaces).isEmpty || detailVM.isPostingComment)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
            }
            .navigationTitle("Discussion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await detailVM.loadComments()
            }
        }
    }
}
