import ComposableArchitecture
import Features
import Models
import SwiftUI

struct SessionsView: View {
  let store: StoreOf<SessionsFeature>
  @State private var sessions: [SessionWrapper] = []

  var body: some View {
    // List of sessions
    List(sessions) { session in
      sessionCell(session)
    }
    .task {
      do {
        let client = SessionDataClient.live
        let allSessions = try await client.fetchSchedules(nil)
        self.sessions = allSessions.map(SessionWrapper.init)
      } catch {

      }
    }
  }

  @ViewBuilder
  private func sessionCell(_ session: SessionWrapper) -> some View {
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
}

#Preview {
  SessionsView(
    store: .init(
      initialState: SessionsFeature.State(),
      reducer: { SessionsFeature() }
    )
  )
}
