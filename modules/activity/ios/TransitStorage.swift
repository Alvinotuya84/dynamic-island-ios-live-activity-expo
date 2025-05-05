import ExpoModulesCore
import WidgetKit

public class TransitStorageModule: Module {
  public func definition() -> ModuleDefinition {
    Name("TransitStorage")
    
    Function("set") { (appGroup: String, key: String, value: JSValue) in
      guard let defaults = UserDefaults(suiteName: appGroup) else {
        throw NSError(domain: "TransitStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access UserDefaults for group \(appGroup)"])
      }
      
      if value.isNull || value.isUndefined {
        defaults.removeObject(forKey: key)
      } else {
        do {
          let jsonData = try JSONSerialization.data(withJSONObject: value.rawValue as Any)
          defaults.set(jsonData, forKey: key)
        } catch {
          throw error
        }
      }
      defaults.synchronize()
    }
    
    Function("reloadWidget") { () in
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
    }
  }
}