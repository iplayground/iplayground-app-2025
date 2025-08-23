import ComposableArchitecture
import Models

extension SharedKey where Self == InMemoryKey<[SessionWrapper]> {
  static var day1Sessions: Self { .inMemory("day1Sessions") }
  static var day2Sessions: Self { .inMemory("day2Sessions") }
}

extension SharedKey where Self == InMemoryKey<IdentifiedArrayOf<Speaker>> {
  static var speakers: Self { .inMemory("speakers") }
}

extension SharedKey where Self == InMemoryKey<SponsorsData> {
  static var sponsorData: Self { .inMemory("sponsorData") }
}

extension SharedKey where Self == InMemoryKey<[Staff]> {
  static var staffs: Self { .inMemory("staffs") }
}

extension SharedKey where Self == InMemoryKey<[Link]> {
  static var links: Self { .inMemory("links") }
}
