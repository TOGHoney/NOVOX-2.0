import SwiftUI

/// Modal sheet for creating a new speaking debate room.
public struct CreateDebateRoomSheet: View {
    @ObservedObject public var debatesVM: DebatesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var topic: String = ""
    @State private var prompt: String = ""
    @State private var language: String = "English"
    @State private var level: String = "A1"
    @State private var maxParticipants: Int = 6
    @State private var isSubmitting: Bool = false
    
    public init(debatesVM: DebatesViewModel) {
        self.debatesVM = debatesVM
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Topic & Prompt") {
                    TextField("Debate Topic (e.g. AI in Education)", text: $topic)
                    TextField("Discussion Prompt / Premise", text: $prompt, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section("Language & Proficiency") {
                    Picker("Language", selection: $language) {
                        ForEach(Constants.targetLanguages) { lang in
                            Text("\(lang.flag) \(lang.name)").tag(lang.name)
                        }
                    }
                    
                    Picker("CEFR Level", selection: $level) {
                        ForEach(Constants.cefrLevels) { cefr in
                            Text("\(cefr.code) - \(cefr.title)").tag(cefr.code)
                        }
                    }
                }
                
                Section("Room Capacity") {
                    Stepper("Max Speakers: \(maxParticipants)", value: $maxParticipants, in: 2...20)
                }
                
                Section {
                    Button(action: {
                        isSubmitting = true
                        Task {
                            if let created = await debatesVM.createRoom(
                                topic: topic,
                                prompt: prompt,
                                language: language,
                                level: level,
                                maxParticipants: maxParticipants
                            ) {
                                dismiss()
                                Task {
                                    _ = await debatesVM.joinRoom(id: created.id)
                                }
                            }
                            isSubmitting = false
                        }
                    }) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Launch Discussion Room")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .listRowBackground(Constants.Colors.brandBurgundy)
                    .disabled(topic.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Host a Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
