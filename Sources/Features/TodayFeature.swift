import ComposableArchitecture
import SessionData

@Reducer
package struct TodayFeature {
  @ObservableState
  package struct State: Equatable {
    package var day1Sessions: [Session] = []
    package var day2Sessions: [Session] = []
    package var selectedDay: Day = .day1

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
            let day1Sessions = try await client.fetchSchedules(1)
            await send(.binding(.set(\.day1Sessions, day1Sessions)))
          }
          group.addTask {
            @Dependency(\.iPlaygroundDataClient) var client
            let day2Sessions = try await client.fetchSchedules(2)
            await send(.binding(.set(\.day2Sessions, day2Sessions)))
          }
        }
      }
    }
  }
}
