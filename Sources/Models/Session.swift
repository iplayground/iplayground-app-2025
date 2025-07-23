import Foundation

package struct Session: Identifiable {
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
}
