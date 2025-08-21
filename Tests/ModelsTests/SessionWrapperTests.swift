import Foundation
import Testing

@testable import Models

@Suite("SessionWrapper Tests")
struct SessionWrapperTests {

  @Test("Parse valid time range for day 1")
  func parseValidTimeRangeDay1() {
    let date = createDate(year: 2025, month: 8, day: 30)
    let wrapper = SessionWrapper(
      date: date,
      timeRange: "11:30 - 11:50",
      title: "Test Session",
      speaker: "Test Speaker",
      speakerID: 0,
      tags: nil,
      description: nil
    )

    #expect(wrapper.dateInterval != nil)

    if let dateInterval = wrapper.dateInterval {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

      let startComponents = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: dateInterval.start)
      let endComponents = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: dateInterval.end)

      #expect(startComponents.year == 2025)
      #expect(startComponents.month == 8)
      #expect(startComponents.day == 30)
      #expect(startComponents.hour == 11)
      #expect(startComponents.minute == 30)

      #expect(endComponents.year == 2025)
      #expect(endComponents.month == 8)
      #expect(endComponents.day == 30)
      #expect(endComponents.hour == 11)
      #expect(endComponents.minute == 50)
    }
  }

  @Test("Parse valid time range for day 2")
  func parseValidTimeRangeDay2() {
    let date = createDate(year: 2025, month: 8, day: 31)
    let wrapper = SessionWrapper(
      date: date,
      timeRange: "09:40 - 10:30",
      title: "Test Session",
      speaker: "Test Speaker",
      speakerID: 0,
      tags: nil,
      description: nil
    )

    #expect(wrapper.dateInterval != nil)

    if let dateInterval = wrapper.dateInterval {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

      let startComponents = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: dateInterval.start)
      let endComponents = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: dateInterval.end)

      #expect(startComponents.year == 2025)
      #expect(startComponents.month == 8)
      #expect(startComponents.day == 31)
      #expect(startComponents.hour == 9)
      #expect(startComponents.minute == 40)

      #expect(endComponents.year == 2025)
      #expect(endComponents.month == 8)
      #expect(endComponents.day == 31)
      #expect(endComponents.hour == 10)
      #expect(endComponents.minute == 30)
    }
  }

  @Test("Parse invalid time range returns nil")
  func parseInvalidTimeRange() {
    let date = createDate(year: 2025, month: 8, day: 30)

    let invalidFormats = [
      "",
      "invalid",
      "11:30",
      "25:30 - 11:50",
      "11:60 - 11:50",
      "11:30 - 25:50",
    ]

    for invalidFormat in invalidFormats {
      let wrapper = SessionWrapper(
        date: date,
        timeRange: invalidFormat,
        title: "Test Session",
        speaker: "Test Speaker",
        speakerID: 0,
        tags: nil,
        description: nil
      )

      #expect(wrapper.dateInterval == nil, "Expected nil for invalid format: \(invalidFormat)")
    }
  }

  @Test("Parse time range with Session init")
  func parseTimeRangeWithSessionInit() {
    let date = createDate(year: 2025, month: 8, day: 30)
    let session = createMockSession(time: "14:15 - 15:05")

    let wrapper = SessionWrapper(date: date, session: session)

    #expect(wrapper.dateInterval != nil)

    if let dateInterval = wrapper.dateInterval {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

      let startComponents = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: dateInterval.start)
      let endComponents = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: dateInterval.end)

      #expect(startComponents.hour == 14)
      #expect(startComponents.minute == 15)
      #expect(endComponents.hour == 15)
      #expect(endComponents.minute == 5)
    }
  }

  @Test("Parse time range with various separators")
  func parseTimeRangeVariousSeparators() {
    let date = createDate(year: 2025, month: 8, day: 30)

    let validFormats = [
      "11:30 – 11:50",  // en dash with spaces
      "11:30 - 11:50",  // hyphen with spaces
      "11:30-11:50",  // hyphen without spaces
      "11:30—11:50",  // em dash without spaces
    ]

    for format in validFormats {
      let wrapper = SessionWrapper(
        date: date,
        timeRange: format,
        title: "Test Session",
        speaker: "Test Speaker",
        speakerID: 0,
        tags: nil,
        description: nil
      )

      #expect(wrapper.dateInterval != nil, "Expected successful parsing for format: \(format)")

      if let dateInterval = wrapper.dateInterval {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

        let startComponents = calendar.dateComponents([.hour, .minute], from: dateInterval.start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: dateInterval.end)

        #expect(startComponents.hour == 11)
        #expect(startComponents.minute == 30)
        #expect(endComponents.hour == 11)
        #expect(endComponents.minute == 50)
      }
    }
  }

  @Test("Handle cross-midnight time range")
  func handleCrossMidnightTimeRange() {
    let date = createDate(year: 2025, month: 8, day: 30)
    let wrapper = SessionWrapper(
      date: date,
      timeRange: "23:30 - 00:30",
      title: "Late Night Session",
      speaker: "Night Owl",
      speakerID: 0,
      tags: nil,
      description: nil
    )

    #expect(wrapper.dateInterval != nil)

    if let dateInterval = wrapper.dateInterval {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

      let startComponents = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: dateInterval.start)
      let endComponents = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: dateInterval.end)

      #expect(startComponents.day == 30)
      #expect(startComponents.hour == 23)
      #expect(startComponents.minute == 30)

      #expect(endComponents.day == 31)
      #expect(endComponents.hour == 0)
      #expect(endComponents.minute == 30)
    }
  }

  private func createDate(year: Int, month: Int, day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

    let components = DateComponents(year: year, month: month, day: day)
    return calendar.date(from: components)!
  }

  private func createMockSession(time: String) -> Session {
    let jsonString = """
      {
        "time": "\(time)",
        "title": "Mock Session",
        "tags": ["test"],
        "speaker": "Mock Speaker",
        "speakerID": 0,
        "description": "Mock Description"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let decoder = JSONDecoder()
    return try! decoder.decode(Session.self, from: jsonData)
  }
}
