import ComposableArchitecture
import Foundation
import Models
import SessionData

@Reducer
package struct TodayFeature {
  @ObservableState
  package struct State: Equatable {
    package var day1Sessions: [SessionWrapper] = []
    package var day2Sessions: [SessionWrapper] = []
    package var selectedDay: Day = .day1

    package var currentSessions: [SessionWrapper] {
      switch selectedDay {
      case .day1: return day1Sessions
      case .day2: return day2Sessions
      }
    }

    package enum Day: Int, CaseIterable, Identifiable {
      case day1 = 1
      case day2 = 2

      package var id: Int { rawValue }
    }

    package init() {}
  }

  package enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case task
  }

  package init() {}

  package var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce(core)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .binding:
      return .none

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
    }
  }

  private func createDate(year: Int, month: Int, day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

    let components = DateComponents(year: year, month: month, day: day)
    return calendar.date(from: components)!
  }
}
