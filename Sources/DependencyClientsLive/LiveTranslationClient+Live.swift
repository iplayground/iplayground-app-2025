import Dependencies
import DependencyClients
import Foundation
@preconcurrency import LiveTranslationSDK_iOS
import OSLog

private let logger = Logger(subsystem: "DependencyClientsLive", category: "LiveTranslationClient")

extension LiveTranslationClient: DependencyKey {
  public static let liveValue: LiveTranslationClient = {
    logger.info("Using LiveTranslationSDK_iOS")
    let service = LiveTranslationService()

    return LiveTranslationClient(
      getLangSet: { langCode in
        do {
          let response = try await service.getLangSet(.init(langCode: langCode))
          // Convert SDK LangSet to our LangSet type
          var langData: [String: String] = [:]
          // Use the langCodingKey method from the SDK response
          langData[langCode] = await response.langCodingKey(langCode) ?? langCode
          return LangSet(data: langData)
        } catch {
          logger.error("Failed to get language set: \(error)")
          throw error
        }
      },

      getLangList: {
        do {
          let response = try await service.getLangList()
          return response.map { item in
            LanguageItem(
              id: String(item.id),
              langCode: item.langCode,
              name: item.language
            )
          }
        } catch {
          logger.error("Failed to get language list: \(error)")
          throw error
        }
      },

      getChatRoomInfo: { roomNumber in
        do {
          let response = try await service.getChatRoomInfo(.init(interactionKey: roomNumber))
          return ChatRoomInfo(
            chatRoomID: response.chatRoomID,
            chatRoomTitle: response.chatRoomTitle
          )
        } catch {
          logger.error("Failed to get chat room info: \(error)")
          throw error
        }
      },

      chatConnection: { roomNumber in
        AsyncThrowingStream { continuation in
          Task {
            do {
              let stream = service.chatConnection(.init(interactionKey: roomNumber))
              for try await action in stream {
                switch action {
                case .connect:
                  continuation.yield(.connect)
                case .disconnect:
                  continuation.yield(.disconnect)
                case .peerClosed:
                  continuation.yield(.peerClosed)
                case let .responseChat(chatResponse):
                  // Convert SDK chat response to our format
                  for chatItem in chatResponse.contentData.chatList {
                    let compositeChatItem = CompositeChatItem(
                      id: chatItem.id,
                      chatId: chatItem.chatRoomID,
                      text: chatItem.text,
                      translatedText: nil,
                      srcLangCode: chatItem.srcLangCode,
                      dstLangCode: "",
                      timestamp: String(chatItem.timestamp)
                    )
                    continuation.yield(.responseChat(compositeChatItem))
                  }
                case let .responseBatchTranslation(translationResponse):
                  // Convert SDK translation response to our format
                  let translatedItems = translationResponse.contentData.chatList.compactMap {
                    trItem in
                    CompositeChatItem(
                      id: trItem.chatID,
                      chatId: trItem.chatID,
                      text: "",
                      translatedText: trItem.content,
                      srcLangCode: trItem.srcLangCode,
                      dstLangCode: trItem.dstLangCode,
                      timestamp: String(trItem.timestamp)
                    )
                  }
                  continuation.yield(.responseBatchTranslation(translatedItems))
                default:
                  logger.warning("Unknown SDK action type: \(type(of: action))")
                }
              }
              continuation.finish()
            } catch {
              logger.error("Chat connection failed: \(error)")
              continuation.finish(throwing: error)
            }
          }

          continuation.onTermination = { _ in
            logger.info("Chat connection terminated")
          }
        }
      },

      requestBatchTranslation: { requests in
        let sdkRequests = requests.map { request in
          RealTimeEntity.Translation.Request.ContentData(
            chatRoomID: request.chatRoomID,
            chatID: request.chatID,
            srcLangCode: request.srcLangCode,
            dstLangCode: request.dstLangCode,
            timestamp: Int(request.timestamp) ?? 0,
            text: request.text
          )
        }

        await service.requestBatchTranslation(
          RealTimeEntity.Translation.Request(data: sdkRequests))
      }
    )
  }()
}
