import ActivityKit
import SwiftUI

struct TransitActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var startedAt: Date
    var estimatedArrival: Date
    var transitLineName: String
    var vehicleID: String
    var currentStation: String
    var nextStation: String
    var delayMinutes: Int
    
    func getTimeUntilArrival() -> TimeInterval {
      return estimatedArrival.timeIntervalSince(Date())
    }
    
    func isDelayed() -> Bool {
      return delayMinutes > 0
    }
    
    func getFormattedArrivalTime() -> String {
      let formatter = DateFormatter()
      formatter.dateFormat = "h:mm a"
      return formatter.string(from: estimatedArrival)
    }
    
    func getFormattedTimeRemaining() -> String {
      let timeRemaining = getTimeUntilArrival()
      let minutes = Int(timeRemaining / 60)
      if minutes < 1 {
        return "Arriving now"
      } else if minutes == 1 {
        return "1 minute"
      } else {
        return "\(minutes) minutes"
      }
    }
  }
  
  var transitMode: String
  var routeNumber: String
  var destination: String
}