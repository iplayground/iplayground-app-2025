import Foundation
@_exported import SessionData

package struct SessionWrapper: Identifiable {
  package let id = UUID()
  package let timeRange: String
  package let title: String
  package let speaker: String
  package let tags: String?
  package let description: String?

  package init(
    timeRange: String,
    title: String,
    speaker: String,
    tags: String?,
    description: String?
  ) {
    self.timeRange = timeRange
    self.title = title
    self.speaker = speaker
    self.tags = tags
    self.description = description
  }

  package init(session: Session) {
    self.timeRange = session.time
    self.title = session.title
    self.speaker = session.speaker
    self.tags = session.tags.isEmpty ? nil : session.tags.joined(separator: " · ")
    self.description = session.description.isEmpty ? nil : session.description
  }
}
