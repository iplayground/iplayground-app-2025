import ComposableArchitecture
import Dependencies
import Features
import Models
import SwiftUI

struct TodayView: View {
  @Bindable var store: StoreOf<TodayFeature>

  var body: some View {
    NavigationStack {
      VStack {
        ScrollViewReader { proxy in
          List {
            Section {
              sessionList
            } header: {
              dayPicker
            }
          }
          .listStyle(.inset)
          .safeAreaInset(edge: .bottom) {
            VStack {
              Button(
                action: {
                  if let currentSession = store.currentSession {
                    // XXX: Change segmented control first
                    // then scroll to current session cell
                    store.send(.tapNowSection)

                    Task { @MainActor in
                      withAnimation {
                        proxy.scrollTo(currentSession.id)
                      }
                    }
                  }
                },
                label: {
                  nowSection
                }
              )
              .buttonStyle(.plain)
              .padding()
              .background(Material.regular)
            }
          }
        }
      }
      .task {
        store.send(.task)
      }
      .task {
        // TODO: refresh date per minute
      }
      .navigationTitle("議程與活動")
      .navigationBarTitleDisplayMode(.inline)
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
            "iPlayground 倒數中：\(Text(duration.formatted(.units(allowed: [.days, .hours, .minutes],width: .narrow))))"
          )
          Spacer()
        }
      } else if now > endDate {
        // 情況 2：活動已結束
        HStack {
          Text("今年的活動已結束，感謝您的參與！")
          Spacer()
        }
      } else if let currentSession = store.currentSession {
        // 情況 3：活動進行中
        HStack {
          VStack(alignment: .leading) {
            let duration = Duration.seconds(
              currentSession.dateInterval?.end.timeIntervalSince(now) ?? 0)
            Text(
              """
              進行中：\(currentSession.title)\(currentSession.speaker.isEmpty ? "" : " - \(currentSession.speaker)")（剩餘：\(Text(duration.formatted(.units(allowed: [.hours, .minutes], width: .narrow))))）
              """)

            if let nextSession = store.nextSession {
              Text(
                "接下來：\(Text(nextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextSession.title)\(nextSession.speaker.isEmpty ? "" : " - \(nextSession.speaker)")"
              )
            }

            if let nextNextSession = store.nextNextSession {
              Text(
                "再接下來：\(Text(nextNextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextNextSession.title)\(nextNextSession.speaker.isEmpty ? "" : " - \(nextNextSession.speaker)")"
              )
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
        Text("Day \(day.rawValue.description)")  // Localization
          .tag(day)
      }
    }
    .pickerStyle(.segmented)
  }

  @ViewBuilder
  private var sessionList: some View {
    let currentSessionID = store.currentSession?.id

    ForEach(store.currentSessions) { session in
      sessionCell(session)
        .listRowBackground(Color.gray.opacity(session.id == currentSessionID ? 0.3 : 0))
      // TODO: Change highlight color
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
    .id(session.id)
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
