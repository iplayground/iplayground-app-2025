import ComposableArchitecture
import Features
import Models
import SwiftUI

struct SessionsView: View {
  let store: StoreOf<SessionsFeature>

  var body: some View {
    VStack {
      let session = store.day1Sessions.map { SessionWrapper(session: $0) }
      List(session) { session in
        sessionCell(session)
      }
    }
    .task {
      store.send(.task)
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
