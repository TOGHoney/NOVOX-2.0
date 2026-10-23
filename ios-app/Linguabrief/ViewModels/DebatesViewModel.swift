import Foundation
import SwiftUI

/// View model managing Debate Rooms list, room hosting, and live room floor simulation.
@MainActor
public final class DebatesViewModel: ObservableObject {
    
    @Published public var rooms: [DebateRoom] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // Active room state
    @Published public var activeRoom: DebateRoom?
    @Published public var isSpeaking: Bool = false
    @Published public var remainingSpeakingSeconds: Int = 180 // 3-minute budget
    @Published public var isFloorHeldByMe: Bool = false
    @Published public var queuePosition: Int?
    
    private var floorTimer: Timer?
    
    public init() {
        Task {
            await fetchRooms()
        }
    }
    
    // MARK: - Room Management
    
    public func fetchRooms() async {
        isLoading = true
        errorMessage = nil
        do {
            let list: [DebateRoom] = try await APIClient.shared.request(.debateRooms())
            self.rooms = list
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    public func createRoom(
        topic: String,
        prompt: String? = nil,
        language: String = "English",
        level: String = "A1",
        maxParticipants: Int = 6
    ) async -> DebateRoom? {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else { return nil }
        
        let payload = DebateRoomCreateRequest(
            topic: trimmedTopic,
            prompt: prompt,
            language: language,
            level: level,
            maxParticipants: maxParticipants
        )
        
        do {
            let created: DebateRoom = try await APIClient.shared.request(.createDebateRoom(), body: payload)
            self.rooms.insert(created, at: 0)
            return created
        } catch {
            self.errorMessage = error.localizedDescription
            return nil
        }
    }
    
    public func joinRoom(id: String) async -> Bool {
        do {
            struct JoinResponse: Codable {
                let message: String?
                let room: DebateRoom?
            }
            let res: JoinResponse = try await APIClient.shared.request(.joinDebateRoom(id: id))
            self.activeRoom = res.room
            self.remainingSpeakingSeconds = 180
            self.isFloorHeldByMe = false
            self.queuePosition = nil
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    public func leaveRoom() async {
        guard let room = activeRoom else { return }
        floorTimer?.invalidate()
        floorTimer = nil
        
        do {
            try await APIClient.shared.requestVoid(.leaveDebateRoom(id: room.id))
        } catch {}
        
        activeRoom = nil
        isFloorHeldByMe = false
        isSpeaking = false
        queuePosition = nil
        await fetchRooms()
    }
    
    // MARK: - Speaking Floor Simulation
    
    public func requestSpeakingFloor() {
        guard !isFloorHeldByMe else { return }
        
        // Check microphone permission first
        Task {
            let granted = await AudioRecordingService.shared.requestMicrophonePermission()
            guard granted else {
                self.errorMessage = "Microphone access is required to take the speaking floor."
                return
            }
            
            // Grant floor and begin 3-minute speaking timer
            self.isFloorHeldByMe = true
            self.isSpeaking = true
            self.queuePosition = nil
            
            self.floorTimer?.invalidate()
            self.floorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if self.remainingSpeakingSeconds > 0 {
                        self.remainingSpeakingSeconds -= 1
                    } else {
                        self.releaseSpeakingFloor()
                    }
                }
            }
        }
    }
    
    public func releaseSpeakingFloor() {
        floorTimer?.invalidate()
        floorTimer = nil
        isFloorHeldByMe = false
        isSpeaking = false
    }
}
