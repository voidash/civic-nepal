import SwiftUI
import CalendarCore

/// Month/year header with previous/next arrows.
struct MonthNavigationView: View {
    let year: Int
    let month: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 1) {
                Text("\(NepaliDateFormatter.monthNameNp(month)) \(NepaliDateFormatter.toNepaliNumeral(year))")
                    .font(.system(size: 14, weight: .bold))
                Text(NepaliDateFormatter.monthNameEn(month))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.blue.opacity(0.08))
    }
}
