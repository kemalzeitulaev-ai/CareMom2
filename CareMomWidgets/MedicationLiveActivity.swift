#if canImport(ActivityKit)
import ActivityKit
import SwiftUI
import WidgetKit

struct MedicationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MedicationActivityAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: "pills.fill")
                    .font(.title2)
                    .foregroundStyle(WidgetColors.lavender)
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.medicationName)
                        .font(.headline)
                    Text(context.state.scheduledDate, style: .time)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(WidgetColors.coral)
                    Text(context.state.childName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(WidgetColors.cream)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(WidgetColors.lavender)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading) {
                        Text(context.state.medicationName).font(.caption)
                        Text(context.state.scheduledDate, style: .time).font(.headline)
                    }
                }
            } compactLeading: {
                Image(systemName: "pills.fill")
            } compactTrailing: {
                Text(context.state.scheduledDate, style: .time)
                    .font(.caption2.weight(.bold))
            } minimal: {
                Image(systemName: "pills.fill")
            }
        }
    }
}
#endif
