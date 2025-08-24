import Foundation
import OSLog

private let logger = Logger(subsystem: "Models", category: "Configuration")

public enum Configuration {
  /// LiveTranslation room number from xcconfig
  public static var liveTranslationRoomNumber: String {
    if let roomNumber = Bundle.main.infoDictionary?["LIVE_TRANSLATION_ROOM_NUMBER"] as? String,
      !roomNumber.isEmpty
    {
      logger.info("Using room number from xcconfig")
      return roomNumber
    } else {
      logger.error("LIVE_TRANSLATION_ROOM_NUMBER not found in Bundle info - check xcconfig setup!")
      return ""
    }
  }
}
