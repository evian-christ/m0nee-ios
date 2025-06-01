//
//  MonirInsightsWidgetLiveActivity.swift
//  MonirInsightsWidget
//
//  Created by Chan on 01/06/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MonirInsightsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MonirInsightsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MonirInsightsWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MonirInsightsWidgetAttributes {
    fileprivate static var preview: MonirInsightsWidgetAttributes {
        MonirInsightsWidgetAttributes(name: "World")
    }
}

extension MonirInsightsWidgetAttributes.ContentState {
    fileprivate static var smiley: MonirInsightsWidgetAttributes.ContentState {
        MonirInsightsWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MonirInsightsWidgetAttributes.ContentState {
         MonirInsightsWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MonirInsightsWidgetAttributes.preview) {
   MonirInsightsWidgetLiveActivity()
} contentStates: {
    MonirInsightsWidgetAttributes.ContentState.smiley
    MonirInsightsWidgetAttributes.ContentState.starEyes
}
