import ComposableArchitecture
import Dependencies
import Features
import Models
import SwiftUI

@ViewAction(for: TodayFeature.self)
struct TodayView: View {
  @Bindable var store: StoreOf<TodayFeature>
  @State private var nowSectionID: Int = 0

  var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path),
      root: { rootView },
      destination: { store in
        switch store.case {
        case let .speaker(store):
          SpeakerView(store: store)
        }
      }
    )
  }

  @ViewBuilder
  private var rootView: some View {
    VStack(spacing: 0) {
      dayPicker
      ScrollViewReader { proxy in
        List {
          sessionList
        }
        .listStyle(.inset)
        .contentMargins(.vertical, -4, for: .scrollIndicators)
        .searchable(text: $store.searchText)
        .safeAreaInset(edge: .bottom) {
          VStack {
            Button(
              action: {
                if let currentSession = store.currentSession {
                  // XXX: Change segmented control first
                  // then scroll to current session cell
                  send(.tapNowSection)

                  Task { @MainActor in
                    withAnimation {
                      proxy.scrollTo(currentSession.id)
                    }
                  }
                }
              },
              label: {
                nowSection
                  .id(nowSectionID)
              }
            )
            .buttonStyle(.plain)
            .padding()
            .background(Material.regular)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom)
          }
        }
      }
    }
    .navigationTitle(String(localized: "議程與活動", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .task {
      send(.task)
    }
    .task {
      Task {
        while Task.isCancelled == false {
          try await Task.sleep(for: .seconds(15))
          nowSectionID += 1
        }
      }
    }
  }

  @ViewBuilder
  private var nowSection: some View {
    if let startDate = store.day1Sessions.first?.dateInterval?.start,
      let endDate = store.day2Sessions.last?.dateInterval?.end
    {
      @Dependency(\.date.now) var now

      // 情況 1：活動開始之前
      if now < startDate {
        HStack {
          let duration = Duration.seconds(startDate.timeIntervalSince(now))
          Text(
            "iPlayground 倒數中：\(Text(duration.formatted(.units(allowed: [.days, .hours, .minutes],width: .narrow))))",
            bundle: .module
          )
          Spacer()
        }
      } else if now > endDate {
        // 情況 2：活動已結束
        HStack {
          Text("今年的活動已結束，感謝您的參與！", bundle: .module)
          Spacer()
        }
      } else if let currentSession = store.currentSession {
        // 情況 3：活動進行中
        HStack {
          VStack(alignment: .leading) {
            let duration = Duration.seconds(
              currentSession.dateInterval?.end.timeIntervalSince(now) ?? 0)
            Text(verbatim: "・")
              + Text(
                """
                進行中：\(currentSession.title)\(currentSession.speaker.isEmpty ? "" : " - \(currentSession.speaker)")（剩餘：\(Text(duration.formatted(.units(allowed: [.hours, .minutes], width: .narrow))))）
                """,
                bundle: .module
              )
              .foregroundStyle(Color(.iPlaygroundYellow))

            if let nextSession = store.nextSession {
              Text(verbatim: "・")
                + Text(
                  "接下來：\(Text(nextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextSession.title)\(nextSession.speaker.isEmpty ? "" : " - \(nextSession.speaker)")",
                  bundle: .module
                )
                .foregroundStyle(Color(.iPlaygroundPink))
            }

            if let nextNextSession = store.nextNextSession {
              Text(verbatim: "・")
                + Text(
                  "再接下來：\(Text(nextNextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextNextSession.title)\(nextNextSession.speaker.isEmpty ? "" : " - \(nextNextSession.speaker)")",
                  bundle: .module
                )
                .foregroundStyle(Color(.iPlaygroundBlue))
            }
          }
          Spacer()
        }
      }
    }
  }

  @ViewBuilder
  private var dayPicker: some View {
    Picker("", selection: $store.selectedDay) {
      ForEach(TodayFeature.State.Day.allCases) { day in
        (Text(day.localizedStringKey, bundle: .module)
          + Text(verbatim: " - ")
         + Text(day.startOfDay, format: Date.FormatStyle().month(.abbreviated).day()))
          .tag(day)
      }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
    .padding(.bottom, 8)
  }

  @ViewBuilder
  private var sessionList: some View {
    let currentSessionID = store.currentSession?.id

    ForEach(store.currentSessions) { session in
      if session.speakerID != nil {
        Button(
          action: {
            send(.tapSession(session))
          },
          label: {
            HStack {
              sessionCell(session)
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundStyle(Color(.accent))
            }
          }
        )
        .listRowBackground(
          Color(.iPlaygroundYellow).opacity(session.id == currentSessionID ? 0.3 : 0))
      } else {
        sessionCell(session)
          .listRowBackground(
            Color(.iPlaygroundYellow).opacity(session.id == currentSessionID ? 0.3 : 0))
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
        .bold()

      if session.speaker.isEmpty == false {
        Text(session.speaker)
          .font(.subheadline)
      }

      if let tags = session.tags {
        Text(tags)
          .font(.footnote)
          .foregroundColor(.secondary)
      }

      if let description = session.description {
        Text(description)
          .font(.footnote)
          .foregroundColor(.secondary)
      }
    }
    .id(session.id)
  }
}

extension TodayFeature.State.Day {
  var localizedStringKey: LocalizedStringKey {
    switch self {
    case .day1: return "第 1 天"
    case .day2: return "第 2 天"
    }
  }

  var startOfDay: Date {
    switch self {
    case .day1:
      return Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 8, day: 30))!
    case .day2:
      return Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 8, day: 31))!
    }
  }
}

#Preview("活動前") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 8, day: 29, hour: 9, minute: 0))!
      return date
    }()
  }
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
    )
  )
}

#Preview("活動中 - Day 1") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 8, day: 30, hour: 9, minute: 35))!
      return date
    }()
  }
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
    )
  )
}

#Preview("活動中 - Day 2") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 8, day: 31, hour: 17, minute: 10))!
      return date
    }()
  }
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
    )
  )
}

#Preview("活動結束後") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 8, day: 31, hour: 18, minute: 0))!
      return date
    }()
  }
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
    )
  )
}
