//
//  NowWidget.swift
//  NowWidget
//
//  Created by ethanhuang on 2025/8/28.
//

import WidgetKit
import SwiftUI
import Dependencies
import DependencyClients
import Models
import SessionData

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> NowEntry {
    @Dependency(\.date) var date
    let eventStartDate = createDate(year: 2025, month: 8, day: 30).addingTimeInterval(9 * 3600)
    return NowEntry(
      date: date.now,
      phase: .beforeEvent(eventStartDate: eventStartDate)
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (NowEntry) -> ()) {
    @Dependency(\.date) var date
    let eventStartDate = createDate(year: 2025, month: 8, day: 30).addingTimeInterval(9 * 3600)
    let entry = NowEntry(
      date: date.now,
      phase: .beforeEvent(eventStartDate: eventStartDate)
    )
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    Task {
      @Dependency(\.iPlaygroundDataClient) var client
      @Dependency(\.date.now) var now
      
      do {
        // Fetch sessions for both days
        let day1Sessions = try await client.fetchSchedules(1, .cacheFirst)
        let day2Sessions = try await client.fetchSchedules(2, .cacheFirst)
        
        let day1Date = createDate(year: 2025, month: 8, day: 30)
        let day2Date = createDate(year: 2025, month: 8, day: 31)
        
        let day1Wrappers = day1Sessions.map { SessionWrapper(date: day1Date, session: $0) }
        let day2Wrappers = day2Sessions.map { SessionWrapper(date: day2Date, session: $0) }
        let allSessions = day1Wrappers + day2Wrappers
        
        guard let eventStartDate = day1Wrappers.first?.dateInterval?.start,
              let eventEndDate = day2Wrappers.last?.dateInterval?.end else {
          // Fallback entry if no sessions available
          let fallbackStartDate = createDate(year: 2025, month: 8, day: 30).addingTimeInterval(9 * 3600)
          let entry = NowEntry(date: now, phase: .beforeEvent(eventStartDate: fallbackStartDate))
          let timeline = Timeline(entries: [entry], policy: .atEnd)
          completion(timeline)
          return
        }
        
        var entries: [NowEntry] = []
        
        // Before event starts
        if now < eventStartDate {
          entries.append(NowEntry(
            date: now,
            phase: .beforeEvent(eventStartDate: eventStartDate)
          ))
        }
        
        // Generate entries for all session start and end times
        for session in allSessions {
          guard let dateInterval = session.dateInterval else { continue }
          
          // Entry at session start
          let currentSession = findCurrentSession(from: allSessions, at: dateInterval.start)
          let nextSession = findNextSession(from: allSessions, after: dateInterval.start)
          let nextNextSession = findNextNextSession(from: allSessions, after: nextSession)
          
          entries.append(NowEntry(
            date: dateInterval.start,
            phase: .duringEvent(
              currentSession: currentSession,
              nextSession: nextSession,
              nextNextSession: nextNextSession
            )
          ))
          
          // Entry at session end (for transitions)
          let currentAtEnd = findCurrentSession(from: allSessions, at: dateInterval.end)
          let nextAtEnd = findNextSession(from: allSessions, after: dateInterval.end)
          let nextNextAtEnd = findNextNextSession(from: allSessions, after: nextAtEnd)
          
          entries.append(NowEntry(
            date: dateInterval.end,
            phase: .duringEvent(
              currentSession: currentAtEnd,
              nextSession: nextAtEnd,
              nextNextSession: nextNextAtEnd
            )
          ))
        }
        
        // After event ends
        entries.append(NowEntry(
          date: eventEndDate,
          phase: .afterEvent
        ))
        
        // Remove duplicates and sort by date
        entries = Array(Set(entries)).sorted { $0.date < $1.date }
        
        // Filter entries to only include future ones
        let futureEntries = entries.filter { $0.date >= now }
        let finalEntries = futureEntries.isEmpty ? [entries.last].compactMap { $0 } : futureEntries
        
        let timeline = Timeline(entries: finalEntries, policy: .atEnd)
        completion(timeline)
        
      } catch {
        // Fallback entry on error
        let fallbackStartDate = createDate(year: 2025, month: 8, day: 30).addingTimeInterval(9 * 3600)
        let entry = NowEntry(date: now, phase: .beforeEvent(eventStartDate: fallbackStartDate))
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
      }
    }
  }
}

private func createDate(year: Int, month: Int, day: Int) -> Date {
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

private func findNextNextSession(from sessions: [SessionWrapper], after nextSession: SessionWrapper?) -> SessionWrapper? {
  guard let date = nextSession?.dateInterval?.end else {
    return nil
  }
  return sessions.first { $0.dateInterval?.start ?? .distantFuture >= date }
}

struct NowEntry: TimelineEntry, Hashable {
  let date: Date
  let phase: Phase
  
  enum Phase: Equatable, Hashable {
    case beforeEvent(eventStartDate: Date)
    case duringEvent(
      currentSession: SessionWrapper?,
      nextSession: SessionWrapper?,
      nextNextSession: SessionWrapper?
    )
    case afterEvent
  }
}

struct NowWidgetEntryView: View {
  var entry: Provider.Entry
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      switch entry.phase {
      case let .beforeEvent(eventStartDate):
        beforeEventView(eventStartDate: eventStartDate)
      case let .duringEvent(currentSession, nextSession, nextNextSession):
        duringEventView(
          currentSession: currentSession,
          nextSession: nextSession,
          nextNextSession: nextNextSession
        )
      case .afterEvent:
        afterEventView
      }
    }
    .padding()
  }
  
  @ViewBuilder
  private func beforeEventView(eventStartDate: Date) -> some View {
    let duration = Duration.seconds(eventStartDate.timeIntervalSince(entry.date))
    
    Text(
      "iPlayground 倒數中：\(Text(duration.formatted(.units(allowed: [.days, .hours, .minutes], width: .narrow))))"
    )
  }
  
  @ViewBuilder
  private func duringEventView(
    currentSession: SessionWrapper?,
    nextSession: SessionWrapper?,
    nextNextSession: SessionWrapper?
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      if let currentSession = currentSession {
        let duration = Duration.seconds(
          currentSession.dateInterval?.end.timeIntervalSince(entry.date) ?? 0
        )
        Text(verbatim: "・")
          + Text(
            """
            進行中：\(currentSession.title)\(currentSession.speaker.isEmpty ? "" : " - \(currentSession.speaker)")（剩餘：\(Text(duration.formatted(.units(allowed: [.hours, .minutes], width: .narrow))))）
            """
          )
          .foregroundStyle(Color.yellow)
      }
      
      if let nextSession = nextSession {
        Text(verbatim: "・")
          + Text(
            "接下來：\(Text(nextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextSession.title)\(nextSession.speaker.isEmpty ? "" : " - \(nextSession.speaker)")"
          )
          .foregroundStyle(Color.pink)
      }
      
      if let nextNextSession = nextNextSession {
        Text(verbatim: "・")
          + Text(
            "再接下來：\(Text(nextNextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextNextSession.title)\(nextNextSession.speaker.isEmpty ? "" : " - \(nextNextSession.speaker)")"
          )
          .foregroundStyle(Color.blue)
      }
    }
  }
  
  @ViewBuilder
  private var afterEventView: some View {
    Text("今年的活動已結束，感謝您的參與！")
  }
}

struct NowWidget: Widget {
  let kind: String = "NowWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        NowWidgetEntryView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      } else {
        NowWidgetEntryView(entry: entry)
          .padding()
          .background()
      }
    }
    .configurationDisplayName("現在議程")
    .description("顯示目前進行中的議程資訊")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview(as: .systemSmall) {
  NowWidget()
} timeline: {
  NowEntry(
    date: .now,
    phase: .beforeEvent(eventStartDate: createDate(year: 2025, month: 8, day: 30).addingTimeInterval(9 * 3600))
  )
  NowEntry(
    date: .now,
    phase: .afterEvent
  )
}
