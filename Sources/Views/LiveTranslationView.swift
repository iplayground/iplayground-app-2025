import ComposableArchitecture
import Features
import SwiftUI

@ViewAction(for: LiveTranslationFeature.self)
package struct LiveTranslationView: View {
  @Bindable package var store: StoreOf<LiveTranslationFeature>

  package init(store: StoreOf<LiveTranslationFeature>) {
    self.store = store
  }

  package var body: some View {
    NavigationStack {
      LiveTranslationContentView(store: store)
        .navigationTitle(Text("即時翻譯", bundle: .module))
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { send(.showLanguageSheet) }) {
              Image(systemName: "globe")
            }
          }
        }
    }
  }
}

#Preview {
  LiveTranslationView(
    store: Store(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )
  )
}
