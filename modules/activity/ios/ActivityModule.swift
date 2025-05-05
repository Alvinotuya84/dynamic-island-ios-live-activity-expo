import ExpoModulesCore
import ActivityKit
import SwiftUI

public class ActivityModule: Module {
  private var currentActivityId: String?
  private var startedAt: Date?
  private var estimatedArrival: Date?
  
  public func definition() -> ModuleDefinition {
    Name("Activity")
    
    // Defines event names that the module can send to JavaScript.
    Events("onTransitActivityUpdate", "onWidgetDismissTransitActivity")
    
    OnCreate {
      setupNotificationObservers()
    }
    
    AsyncFunction("startActivity") { (transitMode: String, routeNumber: String, destination: String, nextStation: String, currentStation: String, estimatedMinutes: Int, delayMinutes: Int) -> String in
      if #available(iOS 16.2, *) {
        do {
          await self.endAllActivities()
          self.startedAt = Date()
          self.estimatedArrival = Date().addingTimeInterval(TimeInterval(estimatedMinutes * 60))
          
          if !ActivityAuthorizationInfo().areActivitiesEnabled {
            return ""
          }
          
          let attributes = TransitActivityAttributes(
            transitMode: transitMode,
            routeNumber: routeNumber,
            destination: destination
          )
          
          let contentState = TransitActivityAttributes.ContentState(
            startedAt: self.startedAt!,
            estimatedArrival: self.estimatedArrival!,
            transitLineName: "\(routeNumber) to \(destination)",
            vehicleID: "V-\(Int.random(in: 1000...9999))",
            currentStation: currentStation,
            nextStation: nextStation,
            delayMinutes: delayMinutes
          )
          
          let activity = try Activity.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: nil),
            pushType: nil
          )
          
          self.currentActivityId = activity.id
          self.sendActivityUpdateEvent()
          return activity.id
        } catch {
          throw error
        }
      }
      return ""
    }
    
    AsyncFunction("updateActivity") { (activityId: String, nextStation: String, currentStation: String, estimatedMinutes: Int, delayMinutes: Int) -> Bool in
      if #available(iOS 16.2, *) {
        do {
          guard let activity = await self.findActivityById(activityId) else {
            return false
          }
          
          guard let startedAt = self.startedAt else {
            return false
          }
          
          self.estimatedArrival = Date().addingTimeInterval(TimeInterval(estimatedMinutes * 60))
          
          let contentState = TransitActivityAttributes.ContentState(
            startedAt: startedAt,
            estimatedArrival: self.estimatedArrival!,
            transitLineName: activity.attributes.transitMode + " " + activity.attributes.routeNumber,
            vehicleID: "V-\(Int.random(in: 1000...9999))",
            currentStation: currentStation,
            nextStation: nextStation,
            delayMinutes: delayMinutes
          )
          
          await activity.update(using: contentState)
          self.sendActivityUpdateEvent()
          return true
        } catch {
          return false
        }
      }
      return false
    }
    
    AsyncFunction("endActivity") { (activityId: String) -> Bool in
      if #available(iOS 16.2, *) {
        Task {
          await self.endActivity(activityId: activityId)
        }
        return true
      }
      return false
    }
    
    AsyncFunction("endAllActivities") { () -> Bool in
      if #available(iOS 16.2, *) {
        Task {
          await self.endAllActivities()
        }
        return true
      }
      return false
    }
  }
  
  private func setupNotificationObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(dismissIntentHandler),
      name: Notification.Name("dismissTransitActivityFromWidget"),
      object: nil
    )
  }
  
  @objc func dismissIntentHandler(_ notification: Notification) {
    guard let currentId = self.currentActivityId else {
      return
    }
    
    sendEvent("onWidgetDismissTransitActivity", [
      "activityId": currentId
    ])
  }
  
  private func sendActivityUpdateEvent() {
    guard let currentId = self.currentActivityId else { return }
    guard let arrival = self.estimatedArrival else { return }
    
    let now = Date()
    let timeRemaining = Int(arrival.timeIntervalSince(now) / 60)
    
    sendEvent("onTransitActivityUpdate", [
      "activityId": currentId,
      "minutesRemaining": timeRemaining
    ])
  }
  
  @available(iOS 16.2, *)
  private func findActivityById(_ activityId: String) async -> Activity<TransitActivityAttributes>? {
    for activity in Activity<TransitActivityAttributes>.activities {
      if activity.id == activityId {
        return activity
      }
    }
    return nil
  }
  
  @available(iOS 16.2, *)
  private func endActivity(activityId: String) async {
    if let activity = await findActivityById(activityId) {
      await activity.end(dismissalPolicy: .immediate)
      if currentActivityId == activityId {
        currentActivityId = nil
        startedAt = nil
        estimatedArrival = nil
      }
    }
  }
  
  @available(iOS 16.2, *)
  private func endAllActivities() async {
    for activity in Activity<TransitActivityAttributes>.activities {
      await activity.end(dismissalPolicy: .immediate)
    }
    currentActivityId = nil
    startedAt = nil
    estimatedArrival = nil
  }
}