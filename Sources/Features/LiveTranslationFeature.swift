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
      return checkIfLoadingCompleted(state: &state)

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
      }
    }
  }

  private func checkIfLoadingCompleted(state: inout State) -> Effect<Action> {
    if state.hasLoadedLangSet && state.hasLoadedLangList && state.hasLoadedRoomInfo {
      return .send(.initialLoadingCompleted)
    }
    return .none
  }
}
