import ComposableArchitecture
import Features
import SwiftUI

struct HomeView: View {
  let store: StoreOf<HomeFeature>

  init(store: StoreOf<HomeFeature>) {
    self.store = store
  }

  var body: some View {
    TabView {
      Text("Sessions")
        .tabItem{ Label("Sessions", systemImage: "calendar") }

      Text("Sponsors")
        .tabItem { Label("Sponsors", systemImage: "building.2.fill") }

      // TODO: More tabs
      // My
      // About
    }
      .task {
        await store.send(.task).finish()
      }
  }
}

#Preview {
  HomeView(
    store: .init(
      initialState: HomeFeature.State(),
      reducer: { HomeFeature()
      })
  )
}
