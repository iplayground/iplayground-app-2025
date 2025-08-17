import ComposableArchitecture
import Features
import Models
import SwiftUI

struct TodayView: View {
  @Bindable var store: StoreOf<TodayFeature>

  var body: some View {
    VStack {
      List {
        Section {
          Text(
      """
          Now section
          Now section
      """)
        }

        Section(
          content: {
            sessionList
          },
          header: {
            dayPicker
          }
        )
      }
      .listStyle(.inset)
    }
    .task {
      store.send(.task)
    }
  }

  @ViewBuilder
  private var dayPicker: some View {
    Picker("", selection: $store.selectedDay) {
      ForEach(TodayFeature.State.Day.allCases) { day in
        Text("Day " + day.rawValue.description)
          .tag(day)
      }
    }
    .pickerStyle(.segmented)
  }

  @ViewBuilder
  private var sessionList: some View {
    let sessions: [SessionWrapper] = {
      switch store.selectedDay {
      case .day1:
        return store.day1Sessions.map { SessionWrapper(session: $0) }
      case .day2:
        return store.day2Sessions.map { SessionWrapper(session: $0) }
      }
    }()

    ForEach(sessions) { session in
      sessionCell(session)
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
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
    )
  )
}
