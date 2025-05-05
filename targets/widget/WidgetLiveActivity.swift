import ActivityKit
import WidgetKit
import SwiftUI

struct TransitLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TransitActivityAttributes.self) { context in
      // Lock screen/banner UI
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#1A2151"),
            Color(hex: "#1B2838")
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        
        VStack(spacing: 14) {
          HStack(alignment: .center) {
            CircleIconView(
              icon: getTransitIcon(transitMode: context.attributes.transitMode),
              color: getTransitColor(transitMode: context.attributes.transitMode)
            )
            
            VStack(alignment: .leading, spacing: 2) {
              Text("\(context.attributes.routeNumber) to")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
              
              Text(context.attributes.destination)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            }
            
            Spacer()
            
            if context.state.isDelayed() {
              DelayPill(minutes: context.state.delayMinutes)
            }
          }
          
          Divider()
            .background(Color.white.opacity(0.2))
            .padding(.vertical, 2)
          
          HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
              Label {
                Text("Next stop")
                  .font(.caption)
                  .foregroundColor(.white.opacity(0.7))
              } icon: {
                Image(systemName: "mappin.and.ellipse")
                  .font(.caption)
                  .foregroundColor(Color(hex: "#4CAF50"))
              }
              
              Text(context.state.nextStation)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
              Label {
                Text("Arriving")
                  .font(.caption)
                  .foregroundColor(.white.opacity(0.7))
              } icon: {
                Image(systemName: "clock")
                  .font(.caption)
                  .foregroundColor(Color(hex: "#4CAF50"))
              }
              
              Text(context.state.getFormattedTimeRemaining())
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            }
          }
          
          Button(intent: DismissIntent()) {
            HStack {
              Spacer()
              Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
              Text("Dismiss")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
              Spacer()
            }
            .padding(.vertical, 10)
            .background(
              LinearGradient(
                gradient: Gradient(colors: [
                  getTransitColor(transitMode: context.attributes.transitMode).opacity(0.7),
                  getTransitColor(transitMode: context.attributes.transitMode).opacity(0.4)
                ]),
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
          }
          .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
      }
      
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded Dynamic Island
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 12) {
            CircleIconView(
              icon: getTransitIcon(transitMode: context.attributes.transitMode),
              color: getTransitColor(transitMode: context.attributes.transitMode),
              size: 32
            )
            
            VStack(alignment: .leading, spacing: 2) {
              Text(context.attributes.routeNumber)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
              
              Text("to \(context.attributes.destination)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            }
          }
          .padding(.leading, 4)
        }
        
        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 4) {
            Text(context.state.getFormattedTimeRemaining())
              .font(.system(size: 22, weight: .bold, design: .rounded))
              .foregroundColor(.white)
              .monospacedDigit()
            
            Text(context.state.getFormattedArrivalTime())
              .font(.caption)
              .foregroundColor(.white.opacity(0.7))
          }
          .padding(.trailing, 4)
        }
        
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 12) {
            HStack(alignment: .center) {
              StationView(
                label: "Current Station",
                station: context.state.currentStation,
                icon: "location.circle",
                color: Color(hex: "#B0BEC5")
              )
              
              Spacer()
              
              Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
              
              Spacer()
              
              StationView(
                label: "Next Station",
                station: context.state.nextStation,
                icon: "mappin.circle.fill",
                color: Color(hex: "#4CAF50")
              )
            }
            
            if context.state.isDelayed() {
              ZStack {
                RoundedRectangle(cornerRadius: 6)
                  .fill(Color(hex: "#F44336").opacity(0.15))
                  .frame(height: 36)
                
                HStack {
                  Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(hex: "#F44336"))
                  
                  Text("Delayed by \(context.state.delayMinutes) minute\(context.state.delayMinutes > 1 ? "s" : "")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#F44336"))
                  
                  Spacer()
                }
                .padding(.horizontal, 12)
              }
            }
          }
          .padding(.top, 8)
        }
      } compactLeading: {
        HStack(spacing: 4) {
          Image(systemName: getTransitIcon(transitMode: context.attributes.transitMode))
            .font(.caption)
            .foregroundColor(getTransitColor(transitMode: context.attributes.transitMode))
            .frame(width: 20, height: 20)
          
          Text(context.attributes.routeNumber)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
        }
      } compactTrailing: {
        HStack(spacing: 4) {
          if context.state.isDelayed() {
            Image(systemName: "exclamationmark.circle.fill")
              .font(.caption2)
              .foregroundColor(Color(hex: "#F44336"))
          }
          
          Text(context.state.getFormattedTimeRemaining())
            .font(.caption2)
            .fontWeight(.bold)
            .monospacedDigit()
            .foregroundColor(.white)
        }
      } minimal: {
        Image(systemName: getTransitIcon(transitMode: context.attributes.transitMode))
          .font(.caption)
          .foregroundColor(getTransitColor(transitMode: context.attributes.transitMode))
          .frame(width: 20, height: 20)
      }
      .widgetURL(URL(string: "transitpulse://open"))
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
  
  func getTransitColor(transitMode: String) -> Color {
    switch transitMode {
    case "bus":
      return Color(hex: "#4CAF50") // Green
    case "train":
      return Color(hex: "#2196F3") // Blue
    case "subway":
      return Color(hex: "#FF9800") // Orange
    default:
      return Color(hex: "#9E9E9E") // Gray
    }
  }
}

// Helper Views
struct CircleIconView: View {
  let icon: String
  let color: Color
  var size: CGFloat = 36
  
  var body: some View {
    ZStack {
      Circle()
        .fill(color.opacity(0.15))
        .frame(width: size, height: size)
      
      Image(systemName: icon)
        .font(.system(size: size/2.5, weight: .semibold))
        .foregroundColor(color)
    }
  }
}

struct DelayPill: View {
  let minutes: Int
  
  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.caption2)
        .foregroundColor(Color(hex: "#F44336"))
      
      Text("\(minutes)m delay")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(Color(hex: "#F44336"))
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color(hex: "#F44336").opacity(0.15))
    .clipShape(Capsule())
  }
}

struct StationView: View {
  let label: String
  let station: String
  let icon: String
  let color: Color
  
  var body: some View {
    VStack(alignment: .center, spacing: 4) {
      Label {
        Text(label)
          .font(.caption2)
          .foregroundColor(.white.opacity(0.6))
      } icon: {
        Image(systemName: icon)
          .font(.caption2)
          .foregroundColor(color)
      }
      
      Text(station)
        .font(.footnote)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity)
  }
}

// Extension to support hex colors
extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

// Preview data setup
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