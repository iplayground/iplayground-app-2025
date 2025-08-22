import ComposableArchitecture
import Foundation
import Models
import SessionData

@Reducer
package struct TodayFeature {
  @ObservableState
  package struct State: Equatable {
    package var path = StackState<Path.State>()
    package var day1Sessions: [SessionWrapper] = []
    package var day2Sessions: [SessionWrapper] = []
    package var selectedDay: Day = .day1
    var initialLoaded = false

    package var allSessions: [SessionWrapper] {
      day1Sessions + day2Sessions
    }

    package var currentSessions: [SessionWrapper] {
      switch selectedDay {
      case .day1: return day1Sessions
      case .day2: return day2Sessions
      }
    }

    package var currentSession: SessionWrapper? {
      @Dependency(\.date.now) var now
      return allSessions.first { $0.dateInterval?.contains(now) ?? false }
    }

    package var nextSession: SessionWrapper? {
      guard let date = currentSession?.dateInterval?.end else {
        return nil
      }
      return allSessions.first { $0.dateInterval?.start ?? .distantFuture >= date }
    }

    package var nextNextSession: SessionWrapper? {
      guard let date = nextSession?.dateInterval?.end else {
        return nil
      }
      return allSessions.first { $0.dateInterval?.start ?? .distantFuture >= date }
    }

    package enum Day: Int, CaseIterable, Identifiable {
      case day1 = 1
      case day2 = 2

      package var id: Int { rawValue }
    }

    package init() {}
  }

  @CasePathable
  package enum Action: Equatable, BindableAction, ComposableArchitecture.ViewAction {
    case binding(BindingAction<State>)
    case path(StackActionOf<Path>)
    case view(ViewAction)
    case navigateToSpeaker(Speaker)

    @CasePathable
    package enum ViewAction: Equatable {
      case task
      case tapNowSection
      case tapSession(SessionWrapper)
    }
  }

  package init() {}

  package var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce(core)
      .forEach(\.path, action: \.path)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .binding(\.day1Sessions):
      if state.initialLoaded == false {
        // 如果現在時間超過第一天的議程的內容，則把selectedDay切成第二天
        if let lastSessionEnd = state.day1Sessions.last?.dateInterval?.end {
          @Dependency(\.date.now) var now
          if now > lastSessionEnd {
            state.selectedDay = .day2
          }
        }

        state.initialLoaded = true
      }

      return .none

    case .binding:
      return .none

    case .path:
      return .none

    case let .view(viewAction):
      switch viewAction {
      case .task:
        return .run { send in
          await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
              @Dependency(\.iPlaygroundDataClient) var client
              let sessions = try await client.fetchSchedules(1)
              let day1Date = createDate(year: 2025, month: 8, day: 30)
              let day1Sessions = sessions.map { SessionWrapper(date: day1Date, session: $0) }
              await send(.binding(.set(\.day1Sessions, day1Sessions)))
            }
            group.addTask {
              @Dependency(\.iPlaygroundDataClient) var client
              let sessions = try await client.fetchSchedules(2)
              let day2Date = createDate(year: 2025, month: 8, day: 31)
              let day2Sessions = sessions.map { SessionWrapper(date: day2Date, session: $0) }
              await send(.binding(.set(\.day2Sessions, day2Sessions)))
            }
          }
        }

      case .tapNowSection:
        if let currentSession = state.currentSession {
          if state.day1Sessions.first(where: { $0.id == currentSession.id }) != nil {
            state.selectedDay = .day1
          } else if state.day2Sessions.first(where: { $0.id == currentSession.id }) != nil {
            state.selectedDay = .day2
          }
        }
        return .none

      case let .tapSession(session):
        guard let speakerID = session.speakerID else {
          return .none
        }
        return .run { send in
          @Dependency(\.iPlaygroundDataClient) var client
          guard let speaker = try await client.fetchSpeakers()[id: speakerID] else {
            return
          }
          await send(.navigateToSpeaker(speaker))
        }
      }

    case let .navigateToSpeaker(speaker):
      state.path.append(.speaker(.init(speaker: speaker)))
      return .none
    }
  }

  private func createDate(year: Int, month: Int, day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

    let components = DateComponents(year: year, month: month, day: day)
    return calendar.date(from: components)!
  }
}
