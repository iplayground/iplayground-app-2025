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
      VStack {
        if store.isLoading {
          loadingView
        } else if let errorMessage = store.errorMessage {
          errorView(errorMessage: errorMessage)
        } else {
          if store.chatList.isEmpty {
            emptyList
          } else {
            messageList
          }
        }
      }
      .navigationTitle(Text("即時翻譯", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          switchLanguageButton
        }

        ToolbarItem(placement: .topBarTrailing) {
          webpageButton
        }
      }
      .task {
        send(.task)
        send(.connectStream)
      }
      .sheet(isPresented: $store.isShowingLanguageSheet) {
        SelectLanguageSheet(store: store)
          .presentationDetents([.medium, .large])
      }
    }
  }

  @ViewBuilder
  private var switchLanguageButton: some View {
    Button(action: { send(.showLanguageSheet) }) {
      Image(systemName: "globe")
    }
  }

  @ViewBuilder
  private var webpageButton: some View {
    Button(
      action: { send(.tapWebpageButton) },
      label: {
        Image(systemName: "arrow.up.right.square")
      }
    )
  }

  @ViewBuilder
  private var loadingView: some View {
    ProgressView(String(localized: "讀取中…", bundle: .module))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder
  private func errorView(errorMessage: String) -> some View {
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
  }

  @ViewBuilder
  private var messageList: some View {
    ScrollView {
      LazyVStack {
        ForEach(store.chatList) { item in
          Text(item.translatedText ?? item.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding()
        }
      }
    }
  }

  @ViewBuilder
  private var emptyList: some View {
    ContentUnavailableView(
      String(localized: "還沒有訊息", bundle: .module),
      systemImage: "bubble.left.and.bubble.right",
      description: Text("當議程開始時，翻譯將顯示在這裡", bundle: .module)
    )
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

#Preview("No messages yet") {
  let _ = prepareDependencies {
    $0.liveTranslationClient.getLangList = { [] }
    $0.liveTranslationClient.chatConnection = { _ in .never }
  }

  LiveTranslationView(
    store: Store(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )
  )
}
