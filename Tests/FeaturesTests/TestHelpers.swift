import Foundation
import SessionData

func makeSession(
  time: String,
  title: String,
  tags: [String] = [],
  speaker: String,
  speakerID: Speaker.ID?,
  description: String
) -> Session {
  return Session(
    time: time,
    title: title,
    tags: tags,
    speaker: speaker,
    speakerID: speakerID,
    description: description
  )
}
