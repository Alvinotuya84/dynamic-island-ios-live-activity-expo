import ActivityKit
import WidgetKit
import SwiftUI

struct TransitLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TransitActivityAttributes.self) { context in
      // Lock screen/banner UI
      ZStack {
        Color.black.opacity(0.8)
          .clipShape(RoundedRectangle(cornerRadius: 16))
        
        VStack(spacing: 12) {
          HStack {
            Image(systemName: getTransitIcon(transitMode: context.attributes.transitMode))
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)
            
            Text("\(context.attributes.routeNumber) to \(context.attributes.destination)")
              .font(.headline)
              .foregroundColor(.white)
            
            Spacer()
            
            if context.state.isDelayed() {
              Text("\(context.state.delayMinutes) min delay")
                .font(.callout)
                .foregroundColor(Color("delayColor"))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color("delayColor").opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
          }
          
          Divider().background(Color.white.opacity(0.3))
          
          HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
              Text("Next stop:")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
              
              Text(context.state.nextStation)
                .font(.body.bold())
                .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
              Text("Arriving in:")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
              
              Text(context.state.getFormattedTimeRemaining())
                .font(.title2.bold())
                .foregroundColor(.white)
            }
          }
          
          Button(intent: DismissIntent()) {
            HStack {
              Spacer()
              Text("Dismiss")
                .font(.callout)
                .foregroundColor(.white)
              Spacer()
            }
            .padding(.vertical, 8)
            .background(Color("routeColor").opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
          }
          .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
      }
      
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 8) {
            Image(systemName: getTransitIcon(transitMode: context.attributes.transitMode))
              .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
              Text("\(context.attributes.routeNumber)")
                .font(.headline)
                .foregroundColor(.white)
              
              Text("to \(context.attributes.destination)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            }
          }
        }
        
        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing) {
            Text(context.state.getFormattedTimeRemaining())
              .font(.headline)
              .foregroundColor(.white)
            
            Text("ETA: \(context.state.getFormattedArrivalTime())")
              .font(.caption)
              .foregroundColor(.white.opacity(0.8))
          }
        }
        
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 8) {
            HStack {
              Text("Current: \(context.state.currentStation)")
                .font(.callout)
                .foregroundColor(.white)
              
              Spacer()
              
              Text("Next: \(context.state.nextStation)")
                .font(.callout)
                .foregroundColor(.white)
            }
            
            if context.state.isDelayed() {
              HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundColor(Color("delayColor"))
                
                Text("\(context.state.delayMinutes) minute delay")
                  .font(.callout)
                  .foregroundColor(Color("delayColor"))
                
                Spacer()
              }
            }
          }
        }
      } compactLeading: {
        Image(systemName: getTransitIcon(transitMode: context.attributes.transitMode))
          .foregroundColor(.white)
      } compactTrailing: {
        Text(context.state.getFormattedTimeRemaining())
          .font(.caption)
          .foregroundColor(.white)
      } minimal: {
        Image(systemName: getTransitIcon(transitMode: context.attributes.transitMode))
          .foregroundColor(.white)
      }
    }
  }
  
  func getTransitIcon(transitMode: String) -> String {
    switch transitMode {
    case "bus":
      return "bus.fill"
    case "train":
      return "tram.fill"
    case "subway":
      return "train.side.front.car"
    default:
      return "figure.walk"
    }
  }
}

// Preview data for the widget
extension TransitActivityAttributes {
  fileprivate static var preview: TransitActivityAttributes {
    TransitActivityAttributes(
      transitMode: "bus",
      routeNumber: "42",
      destination: "Downtown"
    )
  }
}

extension TransitActivityAttributes.ContentState {
  fileprivate static var onTime: TransitActivityAttributes.ContentState {
    TransitActivityAttributes.ContentState(
      startedAt: Date(),
      estimatedArrival: Date().addingTimeInterval(600),
      transitLineName: "42 to Downtown",
      vehicleID: "BUS-1234",
      currentStation: "Central Park",
      nextStation: "Main Street",
      delayMinutes: 0
    )
  }
  
  fileprivate static var delayed: TransitActivityAttributes.ContentState {
    TransitActivityAttributes.ContentState(
      startedAt: Date(),
      estimatedArrival: Date().addingTimeInterval(900),
      transitLineName: "42 to Downtown",
      vehicleID: "BUS-1234",
      currentStation: "Central Park",
      nextStation: "Main Street",
      delayMinutes: 5
    )
  }
}

#Preview("Notification", as: .content, using: TransitActivityAttributes.preview) {
  TransitLiveActivity()
} contentStates: {
  TransitActivityAttributes.ContentState.onTime
  TransitActivityAttributes.ContentState.delayed
}