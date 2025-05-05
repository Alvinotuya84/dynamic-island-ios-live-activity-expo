import WidgetKit
import SwiftUI

struct TransitProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TransitWidgetEntry {
        TransitWidgetEntry(date: Date(), configuration: TransitConfigurationIntent())
    }

    func snapshot(for configuration: TransitConfigurationIntent, in context: Context) async -> TransitWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.your.bundle.identifier.transitpulse")
        var transitInfo = getDefaultTransitInfo()
        
        // Try to read transit info from shared UserDefaults if available
        if let data = defaults?.data(forKey: "activeTransit"),
           let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            transitInfo = parseTransitInfo(info)
        }
        
        return TransitWidgetEntry(date: Date(), configuration: configuration, transitInfo: transitInfo)
    }
    
    func timeline(for configuration: TransitConfigurationIntent, in context: Context) async -> Timeline<TransitWidgetEntry> {
        var entries: [TransitWidgetEntry] = []
        let defaults = UserDefaults(suiteName: "group.your.bundle.identifier.transitpulse")
        var transitInfo = getDefaultTransitInfo()
        
        // Try to read transit info from shared UserDefaults if available
        if let data = defaults?.data(forKey: "activeTransit"),
           let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            transitInfo = parseTransitInfo(info)
        }
        
        // Create a single entry for now
        let entry = TransitWidgetEntry(date: Date(), configuration: configuration, transitInfo: transitInfo)
        entries.append(entry)
        
        // Update every 5 minutes
        return Timeline(entries: entries, policy: .after(Date().addingTimeInterval(5 * 60)))
    }
    
    // Helper function to parse transit info from UserDefaults
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
    
    // Default transit info when no active tracking is available
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

struct TransitWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: TransitConfigurationIntent
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

struct TransitConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Transit Configuration" }
    static var description: IntentDescription { "Configure your transit widget." }

    @Parameter(title: "Preferred transit type", default: "bus")
    var preferredTransit: String
}

struct TransitWidgetEntryView : View {
    var entry: TransitProvider.Entry
    
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
                        .foregroundColor(Color.red)
                    
                    Text("\(entry.transitInfo.delayMinutes) min delay")
                        .font(.footnote)
                        .foregroundColor(Color.red)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(hex: "#1B2838"))
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

struct widget: Widget {
    let kind: String = "TransitWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TransitConfigurationIntent.self, provider: TransitProvider()) { entry in
            TransitWidgetEntryView(entry: entry)
                .containerBackground(.black.opacity(0.8), for: .widget)
        }
    }
}

extension TransitConfigurationIntent {
    fileprivate static var bus: TransitConfigurationIntent {
        let intent = TransitConfigurationIntent()
        intent.preferredTransit = "bus"
        return intent
    }
    
    fileprivate static var train: TransitConfigurationIntent {
        let intent = TransitConfigurationIntent()
        intent.preferredTransit = "train"
        return intent
    }
}

#Preview(as: .systemSmall) {
    widget()
} timeline: {
    TransitWidgetEntry(date: .now, configuration: .bus)
    TransitWidgetEntry(date: .now, configuration: .train)
}