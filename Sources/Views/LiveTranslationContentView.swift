import ComposableArchitecture
import DependencyClients
import Features
import SwiftUI

@ViewAction(for: LiveTranslationFeature.self)
package struct LiveTranslationContentView: View {
  @Bindable package var store: StoreOf<LiveTranslationFeature>

  package init(store: StoreOf<LiveTranslationFeature>) {
    self.store = store
  }

  package var body: some View {
    VStack {
      if store.isLoading {
        ProgressView(String(localized: "讀取中…", bundle: .module))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let errorMessage = store.errorMessage {
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 48))
            .foregroundColor(.orange)

          Text("發生錯誤", bundle: .module)
            .font(.headline)
            .foregroundColor(.primary)

          Text(errorMessage)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

          Button(String(localized: "重試", bundle: .module)) {
            send(.task)
          }
          .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack {
            ForEach(store.chatList) { item in
              Text(item.translatedText ?? item.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding()
            }

            if store.chatList.isEmpty {
              VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right")
                  .font(.system(size: 48))
                  .foregroundColor(.gray)

                Text("還沒有訊息", bundle: .module)
                  .font(.headline)
                  .foregroundColor(.secondary)

                Text("當議程開始時，翻譯將顯示在這裡", bundle: .module)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .multilineTextAlignment(.center)
              }
              .padding()
            }
          }
        }
      }
    }
    .task {
      send(.task)
      send(.connectStream)
    }
    .sheet(isPresented: $store.isShowingLanguageSheet) {
      SelectLanguageSheet(store: store)
    }
  }
}

#Preview {
  LiveTranslationContentView(
    store: Store(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )
  )
}
