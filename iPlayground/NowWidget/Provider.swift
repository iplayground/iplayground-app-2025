//
//  NowWidget.swift
//  NowWidget
//
//  Created by ethanhuang on 2025/8/28.
//

import Dependencies
import DependencyClients
import Models
import SessionData
import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> NowEntry {
    @Dependency(\.date.now) var now
    let eventStartDate = createDate(year: 2025, month: 8, day: 30).addingTimeInterval(9 * 3600)
    return NowEntry(
      date: now,
      phase: .beforeEvent(eventStartDate: eventStartDate)
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (NowEntry) -> Void) {
    @Dependency(\.date.now) var now
    let eventStartDate = createDate(year: 2025, month: 8, day: 30).addingTimeInterval(9 * 3600)
    let entry = NowEntry(
      date: now,
      phase: .beforeEvent(eventStartDate: eventStartDate)
    )
    completion(entry)
  }

  static func fetchSessions() async throws -> ([Session], [Session]) {
    @Dependency(\.iPlaygroundDataClient) var client
    let day1Sessions = try await client.fetchSchedules(1, .cacheFirst)
    let day2Sessions = try await client.fetchSchedules(2, .cacheFirst)
    return (day1Sessions, day2Sessions)
  }

  static func convertSessions(_ sessions: [Session], date: Date) -> [SessionWrapper] {
    sessions.map { SessionWrapper(date: date, session: $0) }
  }

  static func convertSessionWrappers(_ allSessions: [SessionWrapper]) -> [NowEntry] {
    @Dependency(\.date.now) var now

    guard let eventStartDate = allSessions.first?.dateInterval?.start,
          let eventEndDate = allSessions.last?.dateInterval?.end
    else {
      // Fallback entry if no sessions available
      let fallbackStartDate = createDate(year: 2025, month: 8, day: 30).addingTimeInterval(
        9 * 3600)
      let entry = NowEntry(date: now, phase: .beforeEvent(eventStartDate: fallbackStartDate))
      return [entry]
    }

    var entries: [NowEntry] = []

    // Before event starts
    if now < eventStartDate {
      entries.append(
        NowEntry(
          date: now,
          phase: .beforeEvent(eventStartDate: eventStartDate)
        ))
    }

    // Generate entries for all session start and end times
    for session in allSessions {
      guard let dateInterval = session.dateInterval else { continue }

      // Entry at session start
      let currentSession = session
      let nextSession = findNextSession(from: allSessions, after: dateInterval.start)
      let nextNextSession = findNextNextSession(from: allSessions, after: nextSession)

      entries.append(
        NowEntry(
          date: dateInterval.start,
          phase: .duringEvent(
            currentSession: currentSession,
            nextSession: nextSession,
            nextNextSession: nextNextSession
          )
        ))

      if let nextStart = nextSession?.dateInterval?.start,
         nextStart != dateInterval.end {
        entries.append(
          NowEntry(
            date: dateInterval.end,
            phase: .duringEvent(
              currentSession: nil,
              nextSession: nextSession,
              nextNextSession: nextNextSession
            )
          ))
      }


//      // Entry at session end (for transitions)
//      let currentAtEnd = findCurrentSession(from: allSessions, at: dateInterval.end)
//      let nextAtEnd = findNextSession(from: allSessions, after: dateInterval.end)
//      let nextNextAtEnd = findNextNextSession(from: allSessions, after: nextAtEnd)
//
//      entries.append(
//        NowEntry(
//          date: dateInterval.end,
//          phase: .duringEvent(
//            currentSession: currentAtEnd,
//            nextSession: nextAtEnd,
//            nextNextSession: nextNextAtEnd
//          )
//        ))
    }

    // After event ends
    entries.append(
      NowEntry(
        date: eventEndDate,
        phase: .afterEvent
      ))

    // Remove duplicates and sort by date
    entries = Array(Set(entries)).sorted { $0.date < $1.date }

    // Filter entries to only include future ones
    let futureEntries = entries.filter { $0.date >= now }
    let finalEntries = futureEntries.isEmpty ? [entries.last].compactMap { $0 } : futureEntries

    return finalEntries
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<NowEntry>) -> Void) {
    Task {
      let result: Timeline<NowEntry>

      defer {
        completion(result)
      }

      @Dependency(\.iPlaygroundDataClient) var client

      do {
        // Fetch sessions for both days
        let (day1Sessions, day2Sessions) = try await Self.fetchSessions()
        let day1Date = createDate(year: 2025, month: 8, day: 30)
        let day1Wrappers = Self.convertSessions(day1Sessions, date: day1Date)
        let day2Date = createDate(year: 2025, month: 8, day: 31)
        let day2Wrappers = Self.convertSessions(day2Sessions, date: day2Date)
        let allSessions = day1Wrappers + day2Wrappers
        let entries = Self.convertSessionWrappers(allSessions)
        result = Timeline(entries: entries, policy: .atEnd)
      } catch {
        @Dependency(\.date.now) var now
        // Fallback entry on error
        let fallbackStartDate = createDate(year: 2025, month: 8, day: 30).addingTimeInterval(
          9 * 3600)
        let entry = NowEntry(date: now, phase: .beforeEvent(eventStartDate: fallbackStartDate))
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        result = timeline
      }
    }
  }
}

func createDate(year: Int, month: Int, day: Int) -> Date {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

  let components = DateComponents(year: year, month: month, day: day)
  return calendar.date(from: components)!
}

private func findCurrentSession(from sessions: [SessionWrapper], at date: Date) -> SessionWrapper? {
  return sessions.first { $0.dateInterval?.contains(date) ?? false }
}

private func findNextSession(from sessions: [SessionWrapper], after date: Date) -> SessionWrapper? {
  return sessions.first { ($0.dateInterval?.start ?? .distantFuture) > date }
}

private func findNextNextSession(
  from sessions: [SessionWrapper], after nextSession: SessionWrapper?
) -> SessionWrapper? {
  guard let date = nextSession?.dateInterval?.end else {
    return nil
  }
  return sessions.first { $0.dateInterval?.start ?? .distantFuture >= date }
}
