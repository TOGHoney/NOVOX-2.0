# Linguabrief iOS Native Application

A native iOS 17+ client for Linguabrief (NOVOX/usshorts) built with modern Swift 6 and SwiftUI. It connects directly to the existing Node.js/Express 5/MongoDB backend without modifying existing web application code or database schemas.

---

## 1. Architecture Overview

The native iOS client implements a clean **MVVM + Services** architecture:

```
Linguabrief/
├── Configuration/
│   ├── AppConfig.swift             # Dynamic Backend URL (UserDefaults @AppStorage)
│   └── Constants.swift             # App theme, language codes, CEFR levels, topics
├── Models/                         # Strict Swift Codable data models matching backend schemas
│   ├── User.swift                  # User profile, tokens, CEFR levels
│   ├── Article.swift               # News articles, summaries, translations, extraction
│   ├── SavedWord.swift             # Vocabulary items, lemma, POS, translations
│   ├── FlashcardDeck.swift         # AI decks, generated cards, quiz distractors
│   ├── Bookmark.swift              # Saved article bookmarks & snapshots
│   ├── Comment.swift               # Threaded social comments & replies
│   ├── Contest.swift               # Language contests, quiz questions, leaderboards
│   └── DebateRoom.swift            # Speaking debate rooms, participant states, floor control
├── Services/
│   ├── Network/
│   │   ├── APIClient.swift         # Swift 6 Actor-isolated networking with auto Bearer tokens
│   │   ├── Endpoint.swift          # Type-safe REST endpoint definitions
│   │   └── NetworkError.swift      # Structured error handling & status mapping
│   ├── Storage/
│   │   └── KeychainManager.swift   # Secure Security.framework token storage (no plain-text tokens)
│   ├── Audio/
│   │   ├── AudioRecordingService.swift # AVAudioRecorder with permission management & metering
│   │   └── SpeechSynthesisService.swift# AVSpeechSynthesizer for native multi-language pronunciation
│   └── Linguistics/
│       ├── NativeLinguisticService.swift# Apple NaturalLanguage.framework POS tagging & lemmatization
│       └── DictionaryAPIService.swift   # Fallback dictionary definition & translation
├── ViewModels/                     # @Observable and ObservableObject state managers
│   ├── AuthViewModel.swift         # Session state, login, registration, onboarding
│   ├── FeedViewModel.swift         # Feed fetching, pagination, category filtering, search
│   ├── ArticleDetailViewModel.swift# Reader view, translation, Gemini summary, bookmarks
│   ├── WordIntelligenceViewModel.swift# On-device linguistic analysis & vocabulary saving
│   ├── VocabularyViewModel.swift   # Saved words, AI flashcard generation, quiz engine
│   ├── ContestViewModel.swift      # Live timed contests, question submission, leaderboards
│   └── DebatesViewModel.swift      # Room creation, speaking floor state, timer management
├── Views/
│   ├── Navigation/
│   │   ├── RootView.swift          # Session gatekeeper & onboarding router
│   │   └── MainTabView.swift       # 5-tab native tab bar
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   ├── SignupView.swift
│   │   └── LearningProfileSetupView.swift # Native language & CEFR level selection
│   ├── Feed/
│   │   ├── FeedView.swift          # News stream with topic tabs & search
│   │   ├── ArticleCardView.swift   # Native card layout with CEFR badges & bookmarks
│   │   ├── ArticleReaderView.swift # Immersive distraction-free reader
│   │   └── InteractiveTextView.swift# Interactive tap-to-analyze word engine
│   ├── Vocabulary/
│   │   ├── SavedWordsListView.swift# Vocabulary manager with audio pronunciation
│   │   ├── WordIntelligenceSheet.swift # POS tag, lemma, CEFR score, translation sheet
│   │   ├── FlashcardViewerSheet.swift  # 3D interactive flip card viewer
│   │   └── QuizModalView.swift     # 4-option multiple-choice vocabulary quiz
│   ├── Contests/
│   │   ├── ContestListView.swift   # Active/upcoming contest browser
│   │   ├── ContestRunnerView.swift # Live countdown timer & question runner
│   │   └── ContestLeaderboardView.swift# Ranked leaderboard with podium medals
│   ├── Debates/
│   │   ├── DebateRoomsListView.swift# Live debate room browser
│   │   ├── CreateDebateRoomSheet.swift# Room creator with topic and CEFR constraints
│   │   └── DebateRoomLiveView.swift# Live room with 3-minute speaking timer and mic controls
│   ├── Social/
│   │   └── CommentsSheetView.swift # Native threaded discussion drawer
│   └── Profile/
│       ├── ProfileView.swift       # Learning stats, streak counter, settings & backend IP
│       └── BookmarksListView.swift # Saved articles library
└── Utilities/
    ├── CEFRBadge.swift             # Stylized CEFR badge (A1..C2)
    └── View+Modifiers.swift        # Glassmorphic card styling & design tokens
```

---

## 2. Prerequisites & Environment

- **macOS**: Sonoma 14.0+ (Tested on macOS 15+)
- **Xcode**: Xcode 15.0+ or Xcode 16+ (SDK iOS 17.0+)
- **Simulator / Device**: iOS 17.0 or later (iPhone or iPad)
- **Node.js**: v18.0+ for running the backend
- **MongoDB**: Local MongoDB instance or MongoDB Atlas cluster

---

## 3. How to Run the Backend

The native iOS client connects to the existing Node.js/Express backend located in `NOVOX/usshorts/backend`:

1. Open your terminal and navigate to the backend directory:
   ```bash
   cd /Users/kiet36/Desktop/NOVOX/NOVOX/usshorts/backend
   ```
2. Verify or create your `.env` configuration file:
   ```env
   PORT=5000
   MONGO_URI=mongodb://localhost:27017/linguabrief
   JWT_SECRET=your_jwt_secret_key_here
   NEWS_API_KEY=your_news_api_key
   GEMINI_API_KEY=your_gemini_api_key
   ```
3. Install dependencies (if not already installed):
   ```bash
   npm install
   ```
4. Start the backend server:
   ```bash
   node server.js
   # Or using nodemon:
   npx nodemon server.js
   ```
5. Ensure the server logs:
   ```
   Server running on port 5000
   MongoDB Connected successfully
   ```

---

## 4. How to Configure the Backend URL in iOS

The iOS application avoids hardcoded IP addresses through `AppConfig.swift` and an in-app Settings configuration:

### For iOS Simulator:
- By default, `AppConfig.shared.baseURL` is configured to `http://127.0.0.1:5000/api`.
- The iOS Simulator shares the Mac host loopback network, allowing direct connectivity to `127.0.0.1:5000`.

### For Physical iPhone / iPad:
1. Find your Mac's local network IP address:
   ```bash
   ipconfig getifaddr en0
   # Example output: 192.168.1.105
   ```
2. Launch the Linguabrief app on your device or simulator.
3. Navigate to **Profile Tab -> Developer / Backend Server URL**.
4. Enter your Mac's LAN address:
   ```
   http://192.168.1.105:5000/api
   ```
5. Tap **Save Server URL**. The setting is immediately persisted in `UserDefaults` (`@AppStorage("backend_base_url")`) and used for all subsequent API requests without requiring an app rebuild.

---

## 5. Opening and Building in Xcode

1. Open the project in Xcode:
   ```bash
   open /Users/kiet36/Desktop/NOVOX/NOVOX/ios-app/Linguabrief.xcodeproj
   ```
2. Select the `Linguabrief` target and choose any iOS 17+ Simulator (e.g. *iPhone 16 Pro*, *iPhone 17 Pro*).
3. Press `Cmd + B` to build or `Cmd + R` to run.
4. To build via command-line terminal:
   ```bash
   cd /Users/kiet36/Desktop/NOVOX/NOVOX/ios-app
   xcodebuild -project Linguabrief.xcodeproj -scheme Linguabrief -destination 'generic/platform=iOS Simulator' build
   ```

---

## 6. Permissions & Security

### Microphone Usage
- The app declares `NSMicrophoneUsageDescription` in `Info.plist`:
  > *"Linguabrief uses your microphone for real-time speech practice and language debate rooms."*
- `AudioRecordingService` automatically requests permission using `AVAudioApplication.requestRecordPermission()` (iOS 17+) before initiating audio capture.

### App Transport Security (ATS)
- `Info.plist` is pre-configured with `NSAllowsLocalNetworking: true` and `NSAllowsArbitraryLoads: true` for development, permitting HTTP calls to `127.0.0.1` and local Wi-Fi addresses.

### Keychain Token Storage
- User JWTs are stored in the secure Apple Keychain using `Security.framework` (`kSecClassGenericPassword`), safeguarding authentication tokens against disk extraction or sandbox leakage.

---

## 7. Features Implemented & Backend Reused

| Feature Area | iOS Implementation | Backend Endpoint / Service Reused |
|---|---|---|
| **Authentication** | `LoginView`, `SignupView`, `AuthViewModel`, `KeychainManager` | `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/profile` |
| **Language Onboarding** | `LearningProfileSetupView` (CEFR A1–C2, 5 Target & 6 Native Languages) | `PUT /api/auth/profile` |
| **News Feed** | `FeedView`, `ArticleCardView`, 11 Categories, Pull-to-refresh | `GET /api/news/feed`, `GET /api/news/top-headlines` |
| **Article Reader** | `ArticleReaderView`, Gemini AI Summary, Full Translation | `POST /api/ai/batch-summarize`, `POST /api/ai/translate` |
| **Linguistic Analysis** | `InteractiveTextView`, `WordIntelligenceSheet`, POS Tagging | Apple `NaturalLanguage.framework` + `GET https://api.dictionaryapi.dev` |
| **Vocabulary Bank** | `SavedWordsListView`, Native TTS Pronunciation | `GET /api/vocabulary`, `POST /api/vocabulary`, `DELETE /api/vocabulary/:id` |
| **Flashcards & Quiz** | `FlashcardViewerSheet`, `QuizModalView`, 3D Flip Card | `GET /api/flashcards`, `POST /api/flashcards/generate` |
| **Language Contests** | `ContestListView`, `ContestRunnerView`, `ContestLeaderboardView` | `GET /api/contests`, `POST /api/contests/:id/submit`, `GET /api/contests/:id/leaderboard` |
| **Debate Rooms** | `DebateRoomsListView`, `CreateDebateRoomSheet`, `DebateRoomLiveView` | `GET /api/debates`, `POST /api/debates`, `GET /api/debates/:id` |
| **Bookmarks** | `BookmarksListView`, Bookmark Toggle Button | `GET /api/bookmarks`, `POST /api/bookmarks`, `DELETE /api/bookmarks/:id` |
| **Social Discussions** | `CommentsSheetView`, Threaded Comments & Replies | `GET /api/comments/article/:id`, `POST /api/comments` |
| **Speaking & Audio** | `AudioRecordingService`, `SpeechSynthesisService` | Apple `AVFoundation` (`AVAudioRecorder`, `AVSpeechSynthesizer`) |

---

## 8. Limitations & Future Integrations

1. **WebRTC Media Transport**:
   - The debate room interface models the exact 3-minute speaking budget, floor grant/yield states, and participant audio mute controls from the web app.
   - For complete peer-to-peer audio streaming, integrating `WebRTC.framework` or LiveKit client SDK with the backend Socket.IO signaling server is required once audio relay servers are configured.
2. **Server-Side Speech Transcription**:
   - As identified in the repository audit, the backend does not yet provide Whisper/Deepgram server transcription endpoints.
   - The iOS client provides native `AVAudioRecorder` capture with metering and native `AVSpeechSynthesizer` multi-lingual pronunciation, and is pre-architected to stream recorded M4A audio to a transcription route when implemented.
