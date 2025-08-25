import ComposableArchitecture
import Models

extension SharedKey where Self == InMemoryKey<[SessionWrapper]> {
  package static var day1Sessions: Self { .inMemory("day1Sessions") }
  package static var day2Sessions: Self { .inMemory("day2Sessions") }
}

extension SharedKey where Self == InMemoryKey<IdentifiedArrayOf<Speaker>> {
  package static var speakers: Self { .inMemory("speakers") }
}

extension SharedKey where Self == InMemoryKey<SponsorsData> {
  package static var sponsorData: Self { .inMemory("sponsorData") }
}

extension SharedKey where Self == InMemoryKey<[Staff]> {
  package static var staffs: Self { .inMemory("staffs") }
}

extension SharedKey where Self == InMemoryKey<[Link]> {
  package static var links: Self { .inMemory("links") }
}
