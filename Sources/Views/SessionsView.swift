import ComposableArchitecture
import Features
import SwiftUI
import Models

struct SessionsView: View {
  let store: StoreOf<SessionsFeature>

  var body: some View {
    // List of sessions
    List(sampleSessions) { session in
      sessionCell(session)
    }
  }

  @ViewBuilder
  private func sessionCell(_ session: Session) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(session.timeRange)
        .font(.footnote)
        .foregroundColor(.secondary)

      Text(session.title)
        .font(.headline)

      Text(session.speaker)
        .font(.subheadline)

      if let tags = session.tags {
        Text(tags)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      if let description = session.description {
        Text(description)
          .font(.body)
          .foregroundColor(.primary)
          .padding(.top, 2)
      }
    }
    .padding(.vertical, 4)
  }

  // Sample data
  private var sampleSessions: [Session] {
    [
      Session(
        timeRange: "09:30 – 09:40",
        title: "開場",
        speaker: "總召",
        tags: nil,
        description: nil
      ),
      Session(
        timeRange: "09:50 – 10:40",
        title: "Let's Functional Programming in Your Swift Code",
        speaker: "鄭宇哲 UJ Cheng",
        tags: "Swift · 架構 · 性能 · 函數式",
        description:
          "如何讓 Swift 程式碼更簡潔、可讀，是許多開發者追求的目標。函數式編程提供了一種更具表達力的寫法，讓我們能以直觀的語意處理資料與邏輯。本演講將介紹 Swift 到目前為止有的高階函數與使用技巧，並實際示範它們如何應用在 iOS 專案開發中，甚至是在刷題過程中。無論是提升演算法解題效率，還是改善專案架構，Functional Programming 都能為你的 Swift 程式碼帶來優雅的轉變。"
      ),
      Session(
        timeRange: "10:55 – 11:15",
        title: "Swift C++ Interop",
        speaker: "zonble",
        tags: "Swift · 性能 · Interop · 原生",
        description:
          "Swift C++ Interop 是在 2020 年左右開始開發，在 2023 年 WWDC 上宣布的特性，這幾年也不斷有新的變化。在這個 talk 中，會提到如何在 Swift 專案中混用 C++ 語法，以及使用時會遇到的限制與挑戰。"
      ),
    ]
  }
}

#Preview {
  SessionsView(
    store: .init(
      initialState: SessionsFeature.State(),
      reducer: { SessionsFeature() }
    )
  )
}
