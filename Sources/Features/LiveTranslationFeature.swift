import ComposableArchitecture
import DependencyClients
import Foundation
import Models
import OSLog

private let logger = Logger(subsystem: "Features", category: "LiveTranslationFeature")

@Reducer
package struct LiveTranslationFeature {

  private enum CancelID {
    case stream
  }

  private static let localeMapping: [String: String] = [
    // Chinese variants
    "zh-Hant": "zh-TW",  // Traditional Chinese
    "zh-Hant-TW": "zh-TW",
    "zh-Hant-HK": "zh-TW",
    "zh-Hant-MO": "zh-TW",
    "zh-Hans": "zh-CN",  // Simplified Chinese
    "zh-Hans-CN": "zh-CN",
    "zh": "zh-CN",  // Default Chinese maps to Simplified

    // Cantonese
    "yue": "yue",
    "yue-Hant": "yue",
    "zh-HK": "yue",  // Hong Kong commonly uses Cantonese

    // Portuguese variants
    "pt-BR": "pt-BR",  // Brazilian Portuguese
    "pt": "pt",  // European Portuguese
    "pt-PT": "pt",

    // Japanese variants
    "ja-JP": "ja",  // Japan Japanese

    // Korean variants
    "ko-KR": "ko",  // South Korea Korean

    // Direct mappings for other languages
    "ar": "ar",
    "hr": "hr",
    "cs": "cs",
    "nl": "nl",
    "en": "en",
    "fi": "fi",
    "fr": "fr",
    "de": "de",
    "el": "el",
    "he": "he",
    "hi": "hi",
    "hu": "hu",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "km": "km",
    "ko": "ko",
    "ms": "ms",
    "mn": "mn",
    "fa": "fa",
    "pl": "pl",
    "ro": "ro",
    "ru": "ru",
    "sk": "sk",
    "es": "es",
    "sw": "sw",
    "sv": "sv",
    "tl": "tl",
    "th": "th",
    "tr": "tr",
    "uk": "uk",
    "uz": "uz",
    "vi": "vi",
    "ne": "ne",
    "ta": "ta",
    "ur": "ur",
    "si": "si",
    "lo": "lo",
  ]
  @ObservableState
  package struct State: Equatable {
    package var chatList: [CompositeChatItem] = []
    package var langSet: LangSet?
    package var langList: [LanguageItem] = []
    package var roomInfo: ChatRoomInfo?
    package var selectedLangCode: String = "en"
    package var isConnected: Bool = false
    package var isLoading: Bool = true
    package var isShowingLanguageSheet: Bool = false
    package var isUpdatingChat: Bool = false
    package var isUpdatingTranslation: Bool = false
    package var updateChatQueue: [CompositeChatItem] = []
    package var updateTranslationQueue: [CompositeChatItem] = []

    // Internal loading state tracking
    package var hasLoadedLangSet: Bool = false
    package var hasLoadedLangList: Bool = false
    package var hasLoadedRoomInfo: Bool = false

    // Error handling
    package var errorMessage: String? = nil

    package init() {}
  }

  @CasePathable
  package enum Action: Equatable, BindableAction, ComposableArchitecture.ViewAction {
    case view(ViewAction)
    case binding(BindingAction<State>)

    case langSetLoaded(LangSet)
    case langListLoaded([LanguageItem])
    case chatRoomInfoLoaded(ChatRoomInfo)
    case streamActionReceived(StreamAction)
    case connectionStatusChanged(Bool)
    case processChatQueue
    case processTranslationQueue
    case requestTranslation([CompositeChatItem])
    case setInitialLanguage(String)
    case initialLoadingCompleted
    case errorOccurred(String)

    @CasePathable
    package enum ViewAction: Equatable {
      case task
      case connectStream
      case disconnectStream
      case changeLanguage(String)
      case showLanguageSheet
      case hideLanguageSheet
      case tapWebpageButton
    }
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

    case let .langSetLoaded(langSet):
      state.langSet = langSet
      state.hasLoadedLangSet = true
      return checkIfLoadingCompleted(state: &state)

    case let .langListLoaded(langList):
      state.langList = langList
      state.hasLoadedLangList = true

      // Set initial language based on user's locale
      let initialLanguage = Self.determineInitialLanguage(from: langList)
      if initialLanguage != state.selectedLangCode {
        return .concatenate([
          .send(.setInitialLanguage(initialLanguage)),
          checkIfLoadingCompleted(state: &state),
        ])
      } else {
        return checkIfLoadingCompleted(state: &state)
      }

    case let .chatRoomInfoLoaded(roomInfo):
      state.roomInfo = roomInfo
      state.hasLoadedRoomInfo = true
      return checkIfLoadingCompleted(state: &state)

    case .initialLoadingCompleted:
      state.isLoading = false
      return .none

    case let .errorOccurred(error):
      state.errorMessage = error
      state.isLoading = false
      logger.error("LiveTranslation error: \(error)")
      return .none

    case let .streamActionReceived(streamAction):
      switch streamAction {
      case .connect:
        state.isConnected = true
        logger.info("Connected to live translation stream")

      case .disconnect:
        state.isConnected = false
        logger.info("Disconnected from live translation stream")

      case .peerClosed:
        state.isConnected = false
        logger.info("Peer closed live translation stream")
        return .send(.view(.connectStream))

      case let .responseChat(chatItem):
        if state.isUpdatingChat {
          state.updateChatQueue.append(chatItem)
          return .none
        }

        state.isUpdatingChat = true
        if !state.chatList.contains(where: { $0.id == chatItem.id }) {
          state.chatList.append(chatItem)
          state.chatList = Array(state.chatList.suffix(100))
        }
        state.isUpdatingChat = false

        return .concatenate([
          .send(.requestTranslation([chatItem])),
          .send(.processChatQueue),
        ])

      case let .responseBatchTranslation(translatedItems):
        if state.isUpdatingTranslation {
          state.updateTranslationQueue.append(contentsOf: translatedItems)
          return .none
        }

        state.isUpdatingTranslation = true
        for translatedItem in translatedItems {
          if let index = state.chatList.firstIndex(where: { $0.id == translatedItem.id }) {
            var updatedItem = state.chatList[index]
            updatedItem = CompositeChatItem(
              id: updatedItem.id,
              chatId: updatedItem.chatId,
              text: updatedItem.text,
              translatedText: translatedItem.translatedText,
              srcLangCode: updatedItem.srcLangCode,
              dstLangCode: translatedItem.dstLangCode,
              timestamp: updatedItem.timestamp
            )
            state.chatList[index] = updatedItem
          }
        }
        state.isUpdatingTranslation = false

        return .send(.processTranslationQueue)
      }
      return .none

    case let .connectionStatusChanged(isConnected):
      state.isConnected = isConnected
      return .none

    case .processChatQueue:
      guard !state.updateChatQueue.isEmpty else { return .none }

      let nextItem = state.updateChatQueue.removeFirst()
      if !state.chatList.contains(where: { $0.id == nextItem.id }) {
        state.chatList.append(nextItem)
        state.chatList = Array(state.chatList.suffix(100))
      }

      return .concatenate([
        .send(.requestTranslation([nextItem])),
        .send(.processChatQueue),
      ])

    case .processTranslationQueue:
      guard !state.updateTranslationQueue.isEmpty else { return .none }

      let translatedItems = Array(state.updateTranslationQueue.prefix(10))
      state.updateTranslationQueue.removeFirst(min(10, state.updateTranslationQueue.count))

      for translatedItem in translatedItems {
        if let index = state.chatList.firstIndex(where: { $0.id == translatedItem.id }) {
          var updatedItem = state.chatList[index]
          updatedItem = CompositeChatItem(
            id: updatedItem.id,
            chatId: updatedItem.chatId,
            text: updatedItem.text,
            translatedText: translatedItem.translatedText,
            srcLangCode: updatedItem.srcLangCode,
            dstLangCode: translatedItem.dstLangCode,
            timestamp: updatedItem.timestamp
          )
          state.chatList[index] = updatedItem
        }
      }

      return .send(.processTranslationQueue)

    case let .setInitialLanguage(langCode):
      state.selectedLangCode = langCode

      // Load language set for the new language
      return .run { send in
        @Dependency(\.liveTranslationClient) var client
        do {
          let langSet = try await client.getLangSet(langCode)
          await send(.langSetLoaded(langSet))
        } catch {
          logger.error("Failed to load language set for initial language \(langCode): \(error)")
        }
      }

    case let .requestTranslation(chatItems):
      return .run { [selectedLangCode = state.selectedLangCode] send in
        @Dependency(\.liveTranslationClient) var client

        let requests = chatItems.map { item in
          TranslationRequest(
            chatRoomID: item.chatId,
            chatID: item.id,
            srcLangCode: item.srcLangCode,
            dstLangCode: selectedLangCode,
            timestamp: item.timestamp,
            text: item.text
          )
        }

        do {
          try await client.requestBatchTranslation(requests)
        } catch {
          logger.error("Failed to request translation: \(error)")
        }
      }

    case let .view(viewAction):
      switch viewAction {
      case .task:
        state.isLoading = true
        state.errorMessage = nil
        let selectedLangCode = state.selectedLangCode
        return .run { send in
          await withTaskGroup(of: Void.self) { group in
            group.addTask {
              do {
                @Dependency(\.liveTranslationClient) var client
                let langSet = try await client.getLangSet(selectedLangCode)
                await send(.langSetLoaded(langSet))
              } catch {
                await send(
                  .errorOccurred("Failed to load language set: \(error.localizedDescription)"))
              }
            }

            group.addTask {
              do {
                @Dependency(\.liveTranslationClient) var client
                let langList = try await client.getLangList()
                await send(.langListLoaded(langList))
              } catch {
                await send(
                  .errorOccurred("Failed to load language list: \(error.localizedDescription)"))
              }
            }

            group.addTask {
              do {
                @Dependency(\.liveTranslationClient) var client
                let roomInfo = try await client.getChatRoomInfo(
                  Configuration.liveTranslationRoomNumber)
                await send(.chatRoomInfoLoaded(roomInfo))
              } catch {
                // Room info is optional, log the error but don't fail the entire loading
                logger.warning("Failed to load chat room info: \(error.localizedDescription)")
                // Still mark as loaded so the loading can complete
                await send(
                  .chatRoomInfoLoaded(
                    ChatRoomInfo(
                      chatRoomID: Configuration.liveTranslationRoomNumber,
                      chatRoomTitle: "Live Translation"
                    )))
              }
            }
          }
        }

      case .connectStream:
        return .run { send in
          @Dependency(\.liveTranslationClient) var client
          do {
            let stream = client.chatConnection(Configuration.liveTranslationRoomNumber)
            for try await action in stream {
              await send(.streamActionReceived(action))
            }
          } catch {
            logger.error("Stream connection failed: \(error)")
            await send(.connectionStatusChanged(false))
          }
        }
        .cancellable(id: CancelID.stream, cancelInFlight: true)

      case .disconnectStream:
        return .cancel(id: CancelID.stream)

      case let .changeLanguage(langCode):
        state.selectedLangCode = langCode
        state.isShowingLanguageSheet = false

        let existingChatItems = state.chatList

        return .run { send in
          @Dependency(\.liveTranslationClient) var client

          // Load new language set
          do {
            let langSet = try await client.getLangSet(langCode)
            await send(.langSetLoaded(langSet))
          } catch {
            logger.error("Failed to load language set for \(langCode): \(error)")
          }

          // Request translations for existing chat items
          if !existingChatItems.isEmpty {
            await send(.requestTranslation(existingChatItems))
          }
        }

      case .showLanguageSheet:
        state.isShowingLanguageSheet = true
        return .none

      case .hideLanguageSheet:
        state.isShowingLanguageSheet = false
        return .none

      case .tapWebpageButton:
        return .run { send in
          guard
            let url = URL(
              string: "https://livetr.flit.to/chat/\(Configuration.liveTranslationRoomNumber)")
          else { return }
          @Dependency(\.openURL) var openURL
          await openURL(url)
        }
      }
    }
  }

  private func checkIfLoadingCompleted(state: inout State) -> Effect<Action> {
    if state.hasLoadedLangSet && state.hasLoadedLangList && state.hasLoadedRoomInfo {
      return .send(.initialLoadingCompleted)
    }
    return .none
  }

  private static func determineInitialLanguage(from langList: [LanguageItem]) -> String {
    let preferredLanguageID = Locale.preferredLanguages.first ?? "en"
    let availableCodes = Set(langList.map { $0.langCode })

    // 1. Try exact match with preferred language
    if availableCodes.contains(preferredLanguageID) {
      return preferredLanguageID
    }

    // 2. Look up mapping table with preferred language
    if let mapped = localeMapping[preferredLanguageID], availableCodes.contains(mapped) {
      return mapped
    }

    // 3. Extract base language code from preferred language (e.g., "ja" from "ja-JP")
    let baseLanguageCode = String(preferredLanguageID.prefix(2))
    if availableCodes.contains(baseLanguageCode) {
      return baseLanguageCode
    }

    // 4. Look up base language code mapping
    if let mapped = localeMapping[baseLanguageCode], availableCodes.contains(mapped) {
      return mapped
    }

    // 5. Default to English
    return "en"
  }
}
