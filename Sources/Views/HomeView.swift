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
      // Tab 1: Today
      TodayView(
        store: .init(
          initialState: TodayFeature.State(),
          reducer: { TodayFeature() }
        )
      )
      .tabItem { Label("Today", systemImage: "calendar") }

      // Tab 2: Sponsors, Speakers, & Staff
      Text("Sponsors")
        .tabItem { Label("Community", systemImage: "person.3") }

      // Tab 3: Flitto (Live Translation)
      Text("Flitto")
        .tabItem { Label("Flitto", systemImage: "globe") }

      // Tab 4: My
      Text("My")
        .tabItem { Label("My", systemImage: "bookmark") }

      // Tab 5: About
      Text("About")
        .tabItem { Label("About", systemImage: "info.circle") }
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
      reducer: {
        HomeFeature()
      })
  )
}
