import WidgetKit
import SwiftUI

@main
struct CareMomWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CareMomSummaryWidget()
        CareMomMedicationWidget()
        MedicationLiveActivity()
    }
}
