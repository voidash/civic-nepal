import SwiftUI
import CalendarCore

/// Individual day cell in the calendar grid.
struct DayCellView: View {
    let day: Int
    let isToday: Bool
    let isSaturday: Bool
    let isHoliday: Bool
    let hasEvents: Bool
    let hasAuspicious: Bool
    let isSelected: Bool

    private var backgroundColor: Color {
        if isToday {
            return .blue
        } else if isSelected {
            return .blue.opacity(0.15)
        } else if isSaturday || isHoliday {
            return .red.opacity(0.06)
        }
        return .clear
    }

    private var textColor: Color {
        if isToday {
            return .white
        } else if isSaturday || isHoliday {
            return .red
        }
        return .primary
    }

    private var borderColor: Color {
        if isToday {
            return .blue
        } else if isSelected {
            return .blue.opacity(0.4)
        }
        return .gray.opacity(0.2)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)

            Text(NepaliDateFormatter.toNepaliNumeral(day))
                .font(.system(size: 14, weight: isToday ? .bold : .medium))
                .foregroundStyle(textColor)

            // Event/auspicious dots
            if !isToday {
                VStack {
                    Spacer()
                    HStack(spacing: 2) {
                        if hasEvents {
                            Circle()
                                .fill(isHoliday ? .red : .orange)
                                .frame(width: 4, height: 4)
                        }
                        if hasAuspicious {
                            Circle()
                                .fill(.green)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.bottom, 3)
                }
            }
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .overlay(
            Rectangle()
                .stroke(borderColor, lineWidth: isToday || isSelected ? 1.5 : 0.5)
        )
    }
}
