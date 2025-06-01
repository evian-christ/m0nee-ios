//
//  MonirInsightsWidgetBundle.swift
//  MonirInsightsWidget
//
//  Created by Chan on 01/06/2025.
//

import WidgetKit
import SwiftUI

@main
struct MonirInsightsWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonirInsightsWidget()
        MonirInsightsWidgetControl()
        MonirInsightsWidgetLiveActivity()
    }
}
