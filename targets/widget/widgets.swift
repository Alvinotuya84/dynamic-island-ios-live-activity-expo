import WidgetKit
import SwiftUI
import AppIntents

struct TransitInfo {
    let routeType: String
    let routeNumber: String
    let destination: String
    let currentStop: String
    let nextStop: String
    let estimatedMinutes: Int
    let delayMinutes: Int
    
    var isDelayed: Bool {
        return delayMinutes > 0
    }
}

struct SimpleTransitEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    var transitInfo: TransitInfo = TransitInfo(
        routeType: "bus",
        routeNumber: "42",
        destination: "Downtown",
        currentStop: "Central Park",
        nextStop: "Main Street",
        estimatedMinutes: 10,
        delayMinutes: 0
    )
}

struct TransitProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleTransitEntry {
        SimpleTransitEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleTransitEntry {
        let defaults = UserDefaults(suiteName: "group.com.alvindo.transit-pulse-live.transitpulse")
        var transitInfo = getDefaultTransitInfo()
        
        if let data = defaults?.data(forKey: "activeTransit"),
           let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            transitInfo = parseTransitInfo(info)
        }
        
        return SimpleTransitEntry(date: Date(), configuration: configuration, transitInfo: transitInfo)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleTransitEntry> {
        var entries: [SimpleTransitEntry] = []
        let defaults = UserDefaults(suiteName: "group.com.alvindo.transit-pulse-live.transitpulse")
        var transitInfo = getDefaultTransitInfo()
        
        if let data = defaults?.data(forKey: "activeTransit"),
           let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            transitInfo = parseTransitInfo(info)
        }
        
        let entry = SimpleTransitEntry(date: Date(), configuration: configuration, transitInfo: transitInfo)
        entries.append(entry)
        
        return Timeline(entries: entries, policy: .after(Date().addingTimeInterval(5 * 60)))
    }
    
    private func parseTransitInfo(_ info: [String: Any]) -> TransitInfo {
        let routeType = info["routeType"] as? String ?? "bus"
        let routeNumber = info["routeNumber"] as? String ?? "42"
        let destination = info["destination"] as? String ?? "Downtown"
        let currentStop = info["currentStop"] as? String ?? "Central Park"
        let nextStop = info["nextStop"] as? String ?? "Main Street"
        let estimatedMinutes = info["estimatedMinutes"] as? Int ?? 10
        let delayMinutes = info["delayMinutes"] as? Int ?? 0
        
        return TransitInfo(
            routeType: routeType,
            routeNumber: routeNumber,
            destination: destination,
            currentStop: currentStop,
            nextStop: nextStop,
            estimatedMinutes: estimatedMinutes,
            delayMinutes: delayMinutes
        )
    }
    
    private func getDefaultTransitInfo() -> TransitInfo {
        return TransitInfo(
            routeType: "bus",
            routeNumber: "42",
            destination: "Downtown",
            currentStop: "Central Park",
            nextStop: "Main Street",
            estimatedMinutes: 10,
            delayMinutes: 0
        )
    }
}

struct TransitWidgetEntryView : View {
    var entry: SimpleTransitEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: getTransitIcon(transitMode: entry.transitInfo.routeType))
                    .foregroundColor(.white)
                
                Text("\(entry.transitInfo.routeNumber) to \(entry.transitInfo.destination)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next stop:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(entry.transitInfo.nextStop)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Arriving in:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(entry.transitInfo.estimatedMinutes) min")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            if entry.transitInfo.isDelayed {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    
                    Text("\(entry.transitInfo.delayMinutes) min delay")
                        .font(.footnote)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(red: 0.11, green: 0.16, blue: 0.22))
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

struct TransitWidget: Widget {
    let kind: String = "TransitWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: TransitProvider()) { entry in
            TransitWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.black.opacity(0.8)
                }
        }
    }
}

// Preview
#Preview {
    TransitWidgetEntryView(entry: SimpleTransitEntry(
        date: Date(),
        configuration: ConfigurationAppIntent()
    ))
    .previewContext(WidgetPreviewContext(family: .systemSmall))
}