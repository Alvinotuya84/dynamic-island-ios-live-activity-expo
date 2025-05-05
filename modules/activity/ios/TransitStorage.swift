import ExpoModulesCore
import WidgetKit

public class TransitStorageModule: Module {
  public func definition() -> ModuleDefinition {
    Name("TransitStorage")
    
    Function("set") { (appGroup: String, key: String, value: String) -> Void in
      if let defaults = UserDefaults(suiteName: appGroup) {
        defaults.set(value, forKey: key)
        defaults.synchronize()
      }
    }
    
    Function("reloadWidget") { () -> Void in
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
    }
  }
}