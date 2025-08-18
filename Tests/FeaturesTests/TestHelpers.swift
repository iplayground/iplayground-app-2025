import Foundation
import SessionData

func makeSession(
  time: String,
  title: String,
  tags: [String] = [],
  speaker: String,
  description: String
) -> Session {
  // Since Session is Codable, we can use JSON to create it
  let tagsJSON = try! String(data: JSONSerialization.data(withJSONObject: tags), encoding: .utf8)!
  let jsonData = """
    {
      "time": "\(time)",
      "title": "\(title)",
      "tags": \(tagsJSON),
      "speaker": "\(speaker)",
      "description": "\(description)"
    }
    """.data(using: .utf8)!

  // Decode the JSON to create the Session
  return try! JSONDecoder().decode(Session.self, from: jsonData)
}
