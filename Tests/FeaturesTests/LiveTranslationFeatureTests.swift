import ComposableArchitecture
import DependencyClients
import Features
import XCTest

@MainActor
final class LiveTranslationFeatureTests: XCTestCase {

  func testInitialState() async {
    let state = LiveTranslationFeature.State()

    XCTAssertTrue(state.chatList.isEmpty)
    XCTAssertNil(state.langSet)
    XCTAssertTrue(state.langList.isEmpty)
    XCTAssertNil(state.roomInfo)
    XCTAssertEqual(state.selectedLangCode, "en")
    XCTAssertFalse(state.isConnected)
    XCTAssertTrue(state.isLoading)
    XCTAssertFalse(state.isShowingLanguageSheet)
    XCTAssertFalse(state.hasLoadedLangSet)
    XCTAssertFalse(state.hasLoadedLangList)
    XCTAssertFalse(state.hasLoadedRoomInfo)
  }

  func testLangSetLoaded() async {
    let store = TestStore(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )

    let langSet = LangSet(data: ["en": "English", "zh": "中文"])

    await store.send(\.langSetLoaded, langSet) {
      $0.langSet = langSet
      $0.hasLoadedLangSet = true
    }
  }

  func testLangListLoaded() async {
    let store = TestStore(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )

    let langList = [
      LanguageItem(id: "en", langCode: "en", name: "English"),
      LanguageItem(id: "zh", langCode: "zh", name: "中文"),
    ]

    await store.send(\.langListLoaded, langList) {
      $0.langList = langList
      $0.hasLoadedLangList = true
    }
  }

  func testChatRoomInfoLoaded() async {
    let store = TestStore(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )

    let roomInfo = ChatRoomInfo(
      chatRoomID: "490294", chatRoomTitle: "Test Room")

    await store.send(\.chatRoomInfoLoaded, roomInfo) {
      $0.roomInfo = roomInfo
      $0.hasLoadedRoomInfo = true
    }
  }

  func testCompleteInitialLoading() async {
    let store = TestStore(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )

    let langSet = LangSet(data: ["en": "English", "zh": "中文"])
    let langList = [
      LanguageItem(id: "en", langCode: "en", name: "English"),
      LanguageItem(id: "zh", langCode: "zh", name: "中文"),
    ]
    let roomInfo = ChatRoomInfo(
      chatRoomID: "490294", chatRoomTitle: "Test Room")

    await store.send(\.langSetLoaded, langSet) {
      $0.langSet = langSet
      $0.hasLoadedLangSet = true
    }

    await store.send(\.langListLoaded, langList) {
      $0.langList = langList
      $0.hasLoadedLangList = true
    }

    await store.send(\.chatRoomInfoLoaded, roomInfo) {
      $0.roomInfo = roomInfo
      $0.hasLoadedRoomInfo = true
    }

    await store.receive(\.initialLoadingCompleted) {
      $0.isLoading = false
    }
  }

  func testConnectionStatusChanged() async {
    let store = TestStore(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )

    await store.send(\.connectionStatusChanged, true) {
      $0.isConnected = true
    }

    await store.send(\.connectionStatusChanged, false) {
      $0.isConnected = false
    }
  }

  func testStreamActionConnect() async {
    let store = TestStore(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )

    await store.send(\.streamActionReceived, StreamAction.connect) {
      $0.isConnected = true
    }
  }

  func testStreamActionDisconnect() async {
    var initialState = LiveTranslationFeature.State()
    initialState.isConnected = true

    let store = TestStore(
      initialState: initialState,
      reducer: { LiveTranslationFeature() }
    )

    await store.send(\.streamActionReceived, StreamAction.disconnect) {
      $0.isConnected = false
    }
  }

  func testLanguageSheetActions() async {
    let store = TestStore(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )

    await store.send(\.view, .showLanguageSheet) {
      $0.isShowingLanguageSheet = true
    }

    await store.send(\.view, .hideLanguageSheet) {
      $0.isShowingLanguageSheet = false
    }
  }

  func testChangeLanguage() async {
    let store = TestStore(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    ) {
      $0.liveTranslationClient.getLangSet = { langCode in
        switch langCode {
        case "ja":
          return LangSet(data: ["en": "English", "ja": "日本語"])
        default:
          return LangSet(data: ["en": "English", "zh": "中文"])
        }
      }
      $0.liveTranslationClient.requestBatchTranslation = { _ in }
    }

    await store.send(\.view, .changeLanguage("ja")) {
      $0.selectedLangCode = "ja"
      $0.isShowingLanguageSheet = false
    }

    await store.receive(\.langSetLoaded, LangSet(data: ["en": "English", "ja": "日本語"])) {
      $0.langSet = LangSet(data: ["en": "English", "ja": "日本語"])
      $0.hasLoadedLangSet = true
    }

    // Note: requestTranslation is not called when chatList is empty
  }

  func testBindingAction() async {
    let store = TestStore(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )

    await store.send(\.binding, .set(\.selectedLangCode, "ja")) {
      $0.selectedLangCode = "ja"
    }
  }

  func testErrorOccurred() async {
    let store = TestStore(
      initialState: LiveTranslationFeature.State(),
      reducer: { LiveTranslationFeature() }
    )

    await store.send(\.errorOccurred, "Test error") {
      $0.errorMessage = "Test error"
      $0.isLoading = false
    }
  }
}
