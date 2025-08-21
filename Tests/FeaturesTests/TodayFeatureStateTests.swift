import ComposableArchitecture
import Dependencies
import Foundation
import Models
import SessionData
import XCTest

@testable import Features

@MainActor
final class TodayFeatureStateTests: XCTestCase {
  func testInitialState() {
    let state = TodayFeature.State()

    expectNoDifference(state.day1Sessions, [])
    expectNoDifference(state.day2Sessions, [])
    expectNoDifference(state.selectedDay, .day1)
    expectNoDifference(state.initialLoaded, false)
    expectNoDifference(state.allSessions, [])
    expectNoDifference(state.currentSessions, [])
  }

  func testAllSessionsComputation() {
    let day1Session = createMockSessionWrapper(title: "Day 1 Session")
    let day2Session = createMockSessionWrapper(title: "Day 2 Session")

    var state = TodayFeature.State()
    state.day1Sessions = [day1Session]
    state.day2Sessions = [day2Session]

    expectNoDifference(state.allSessions, [day1Session, day2Session])
  }

  func testCurrentSessionsComputation() {
    let day1Session = createMockSessionWrapper(title: "Day 1 Session")
    let day2Session = createMockSessionWrapper(title: "Day 2 Session")

    var state = TodayFeature.State()
    state.day1Sessions = [day1Session]
    state.day2Sessions = [day2Session]

    state.selectedDay = .day1
    expectNoDifference(state.currentSessions, [day1Session])

    state.selectedDay = .day2
    expectNoDifference(state.currentSessions, [day2Session])
  }

  func testCurrentSessionComputationWithActivemakeSession() async {
    let now = Date()
    let sessionDate = Calendar.current.startOfDay(for: now)

    let session = makeSession(
      time: "10:00-11:00",
      title: "Current Session",
      tags: [],
      speaker: "Test Speaker",
      speakerID: 0,
      description: "Test description"
    )

    let sessionWrapper = SessionWrapper(date: sessionDate, session: session)

    withDependencies {
      $0.date.now = sessionDate.addingTimeInterval(10 * 60 * 60 + 30 * 60)
    } operation: {
      var state = TodayFeature.State()
      state.day1Sessions = [sessionWrapper]

      XCTAssertNotNil(state.currentSession)
      expectNoDifference(state.currentSession?.title, "Current Session")
    }
  }

  func testCurrentSessionComputationWhenNoCurrentmakeSession() async {
    let now = Date()
    let sessionDate = Calendar.current.startOfDay(for: now)

    let session = makeSession(
      time: "08:00-09:00",
      title: "Past Session",
      tags: [],
      speaker: "Test Speaker",
      speakerID: 0,
      description: "Test description"
    )

    let sessionWrapper = SessionWrapper(date: sessionDate, session: session)

    withDependencies {
      $0.date.now = sessionDate.addingTimeInterval(12 * 60 * 60)
    } operation: {
      var state = TodayFeature.State()
      state.day1Sessions = [sessionWrapper]

      expectNoDifference(state.currentSession, nil)
    }
  }

  func testNextSessionComputation() async {
    let now = Date()
    let sessionDate = Calendar.current.startOfDay(for: now)

    let currentSession = makeSession(
      time: "10:00-11:00",
      title: "Current Session",
      tags: [],
      speaker: "Test Speaker",
      speakerID: 0,
      description: "Test description"
    )

    let nextSession = makeSession(
      time: "11:00-12:00",
      title: "Next Session",
      tags: [],
      speaker: "Test Speaker",
      speakerID: 0,
      description: "Test description"
    )

    let currentWrapper = SessionWrapper(date: sessionDate, session: currentSession)
    let nextWrapper = SessionWrapper(date: sessionDate, session: nextSession)

    withDependencies {
      $0.date.now = sessionDate.addingTimeInterval(10 * 60 * 60 + 30 * 60)
    } operation: {
      var state = TodayFeature.State()
      state.day1Sessions = [currentWrapper, nextWrapper]

      XCTAssertNotNil(state.nextSession)
      expectNoDifference(state.nextSession?.title, "Next Session")
    }
  }

  func testNextSessionComputationWhenNoCurrentmakeSession() async {
    let now = Date()
    let sessionDate = Calendar.current.startOfDay(for: now)

    let session = makeSession(
      time: "08:00-09:00",
      title: "Past Session",
      tags: [],
      speaker: "Test Speaker",
      speakerID: 0,
      description: "Test description"
    )

    let sessionWrapper = SessionWrapper(date: sessionDate, session: session)

    withDependencies {
      $0.date.now = sessionDate.addingTimeInterval(12 * 60 * 60)
    } operation: {
      var state = TodayFeature.State()
      state.day1Sessions = [sessionWrapper]

      expectNoDifference(state.nextSession, nil)
    }
  }

  func testNextNextSessionComputation() async {
    let now = Date()
    let sessionDate = Calendar.current.startOfDay(for: now)

    let currentSession = makeSession(
      time: "10:00-11:00",
      title: "Current Session",
      tags: [],
      speaker: "Test Speaker 0",
      speakerID: 0,
      description: "Test description"
    )

    let nextSession = makeSession(
      time: "11:00-12:00",
      title: "Next Session",
      tags: [],
      speaker: "Test Speaker 1",
      speakerID: 1,
      description: "Test description"
    )

    let nextNextSession = makeSession(
      time: "12:00-13:00",
      title: "Next Next Session",
      tags: [],
      speaker: "Test Speaker 2",
      speakerID: 2,
      description: "Test description"
    )

    let currentWrapper = SessionWrapper(date: sessionDate, session: currentSession)
    let nextWrapper = SessionWrapper(date: sessionDate, session: nextSession)
    let nextNextWrapper = SessionWrapper(date: sessionDate, session: nextNextSession)

    withDependencies {
      $0.date.now = sessionDate.addingTimeInterval(10 * 60 * 60 + 30 * 60)
    } operation: {
      var state = TodayFeature.State()
      state.day1Sessions = [currentWrapper, nextWrapper, nextNextWrapper]

      XCTAssertNotNil(state.nextNextSession)
      expectNoDifference(state.nextNextSession?.title, "Next Next Session")
    }
  }

  func testNextNextSessionComputationWhenNoNextmakeSession() async {
    let now = Date()
    let sessionDate = Calendar.current.startOfDay(for: now)

    let session = makeSession(
      time: "10:00-11:00",
      title: "Current Session",
      tags: [],
      speaker: "Test Speaker",
      speakerID: 0,
      description: "Test description"
    )

    let sessionWrapper = SessionWrapper(date: sessionDate, session: session)

    withDependencies {
      $0.date.now = sessionDate.addingTimeInterval(10 * 60 * 60 + 30 * 60)
    } operation: {
      var state = TodayFeature.State()
      state.day1Sessions = [sessionWrapper]

      expectNoDifference(state.nextNextSession, nil)
    }
  }

  func testDayEnum() {
    expectNoDifference(TodayFeature.State.Day.day1.id, 1)
    expectNoDifference(TodayFeature.State.Day.day2.id, 2)
    expectNoDifference(TodayFeature.State.Day.day1.rawValue, 1)
    expectNoDifference(TodayFeature.State.Day.day2.rawValue, 2)
    expectNoDifference(TodayFeature.State.Day.allCases, [.day1, .day2])
  }

  // MARK: - Helper Methods

  private func createMockSessionWrapper(
    title: String,
    timeRange: String = "10:00-11:00",
    speaker: String = "Test Speaker"
  ) -> SessionWrapper {
    SessionWrapper(
      timeRange: timeRange,
      title: title,
      speaker: speaker,
      speakerID: 0,
      tags: nil,
      description: "Test description"
    )
  }
}
