import SwiftUI
import CalendarCore

/// Displays today's BS date prominently — large day number, formatted date, weekday, AD equivalent.
struct TodayCardView: View {
    let today: BsDate
    let todayAd: Date

    private var weekday: Int {
        BsDateConverter.weekday(for: today)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Large day number box
            Text(NepaliDateFormatter.toNepaliNumeral(today.day))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 8).fill(.blue))

            VStack(alignment: .leading, spacing: 2) {
                Text("आज: \(NepaliDateFormatter.formatNp(today))")
                    .font(.system(size: 13, weight: .semibold))

                Text("\(NepaliDateFormatter.weekdayNameNp(weekday)) \u{2022} \(NepaliDateFormatter.formatAdDate(todayAd))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(.quaternary.opacity(0.5))
    }
}
