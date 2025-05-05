import WidgetKit
import SwiftUI

@main
struct exportWidgets: WidgetBundle {
    var body: some Widget {
        // Export widgets here
        widget()
        widgetControl()
        TransitLiveActivity() // Replace WidgetLiveActivity with our new one
    }
}