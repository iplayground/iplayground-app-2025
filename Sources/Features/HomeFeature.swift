import ComposableArchitecture
import DependencyClients
import Models

@Reducer
package struct HomeFeature {
  @ObservableState
  package struct State: Equatable {
    package init() {}
  }

  package enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case task
  }

  package init() {}

  package var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce(core)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .binding:
      return .none
      
    case .task:
      return .none
    }
  }
}
