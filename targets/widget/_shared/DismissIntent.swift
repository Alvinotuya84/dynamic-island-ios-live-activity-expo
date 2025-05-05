import AppIntents
import WidgetKit

@available(iOS 16.2, *)
struct DismissIntent: AppIntent, LiveActivityIntent {
  static var title: LocalizedStringResource = "Dismiss Transit Alert"
  static var description: IntentDescription = "Dismisses the transit alert"
  static var openAppWhenRun: Bool = true
  
  init() {}
  
  func perform() async throws -> some IntentResult {
    NotificationCenter.default.post(name: Notification.Name("dismissTransitActivityFromWidget"), object: nil)
    return .result()
  }
}