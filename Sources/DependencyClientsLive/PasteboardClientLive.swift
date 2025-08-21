import Dependencies
import DependenciesMacros
import DependencyClients

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

extension PasteboardClient: DependencyKey {
  public static let liveValue = PasteboardClient(
    copy: { string in
      #if canImport(UIKit)
        UIPasteboard.general.string = string
      #elseif canImport(AppKit)
        NSPasteboard.general.setString(string, forType: .string)
      #endif
    }
  )
}
