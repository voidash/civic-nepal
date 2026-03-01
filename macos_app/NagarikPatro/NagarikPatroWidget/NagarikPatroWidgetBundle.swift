import SwiftUI
import WidgetKit

@main
struct NagarikPatroWidgetBundle: WidgetBundle {
    var body: some Widget {
        NagarikPatroSmallWidget()
        NagarikPatroMediumWidget()
        NagarikPatroLargeWidget()
    }
}
