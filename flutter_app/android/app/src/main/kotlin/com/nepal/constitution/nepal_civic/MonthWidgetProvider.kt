package com.nepal.constitution.nepal_civic

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import java.util.Calendar

class MonthWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        // Nepali month names
        private val nepaliMonths = arrayOf(
            "बैशाख", "जेठ", "असार", "श्रावण", "भदौ", "असोज",
            "कार्तिक", "मंसिर", "पुष", "माघ", "फागुन", "चैत"
        )

        // Holidays by year -> month -> days
        private val holidays = mapOf(
            2081 to mapOf(
                1 to setOf(1, 2, 5, 19),
                2 to setOf(10, 15),
                3 to setOf(3),
                5 to setOf(3, 4, 10, 21),
                6 to setOf(1, 3, 9, 17, 24, 25, 26, 27, 28),
                7 to setOf(15, 16, 17, 18, 19, 22, 25, 30),
                8 to setOf(18, 30),
                9 to setOf(10, 15, 27),
                10 to setOf(1, 16, 17, 21),
                11 to setOf(7, 14, 16, 24, 29),
                12 to setOf(1, 16),
            ),
            2082 to mapOf(
                1 to setOf(1, 2, 18, 29),
                2 to setOf(15, 24),
                4 to setOf(24, 25, 31),
                5 to setOf(10, 15, 21, 30),
                6 to setOf(3, 6, 13, 14, 15, 16, 17, 18),
                7 to setOf(3, 4, 5, 6, 7, 10, 19, 25),
                8 to setOf(17, 18),
                9 to setOf(10, 15, 27),
                10 to setOf(1, 5, 9, 16),
                11 to setOf(3, 6, 7, 18, 19, 24),
                12 to setOf(4, 13),
            ),
            2083 to mapOf(
                1 to setOf(1, 18),
                2 to setOf(15),
                5 to setOf(12, 19, 29),
                6 to setOf(3, 9, 25, 31),
                7 to setOf(1, 3, 4, 5, 6, 23, 24, 25, 29),
                9 to setOf(9, 10),
                10 to setOf(16, 24, 28),
                11 to setOf(22, 25),
                12 to setOf(7, 8),
            ),
        )

        // BS month days for years 2070-2090
        private val bsMonthDays = mapOf(
            2070 to intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
            2071 to intArrayOf(31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30),
            2072 to intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
            2073 to intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
            2074 to intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
            2075 to intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
            2076 to intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
            2077 to intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
            2078 to intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
            2079 to intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
            2080 to intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
            2081 to intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
            2082 to intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
            2083 to intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
            2084 to intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
            2085 to intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
            2086 to intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
            2087 to intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
            2088 to intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
            2089 to intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
            2090 to intArrayOf(31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31)
        )

        // Reference date: 2014-04-13 AD = 2071-01-01 BS
        private val refAdYear = 2014
        private val refAdMonth = 4
        private val refAdDay = 13
        private val refBsYear = 2071
        private val refBsMonth = 1
        private val refBsDay = 1

        // Day cell IDs for the grid
        private val dayCellIds = arrayOf(
            intArrayOf(R.id.day_1_1, R.id.day_1_2, R.id.day_1_3, R.id.day_1_4, R.id.day_1_5, R.id.day_1_6, R.id.day_1_7),
            intArrayOf(R.id.day_2_1, R.id.day_2_2, R.id.day_2_3, R.id.day_2_4, R.id.day_2_5, R.id.day_2_6, R.id.day_2_7),
            intArrayOf(R.id.day_3_1, R.id.day_3_2, R.id.day_3_3, R.id.day_3_4, R.id.day_3_5, R.id.day_3_6, R.id.day_3_7),
            intArrayOf(R.id.day_4_1, R.id.day_4_2, R.id.day_4_3, R.id.day_4_4, R.id.day_4_5, R.id.day_4_6, R.id.day_4_7),
            intArrayOf(R.id.day_5_1, R.id.day_5_2, R.id.day_5_3, R.id.day_5_4, R.id.day_5_5, R.id.day_5_6, R.id.day_5_7),
            intArrayOf(R.id.day_6_1, R.id.day_6_2, R.id.day_6_3, R.id.day_6_4, R.id.day_6_5, R.id.day_6_6, R.id.day_6_7)
        )

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.month_widget)

            // Get current date and convert to BS
            val cal = Calendar.getInstance()
            val year = cal.get(Calendar.YEAR)
            val month = cal.get(Calendar.MONTH)
            val day = cal.get(Calendar.DAY_OF_MONTH)

            val bsDate = adToBs(year, month + 1, day)
            val currentDay = bsDate.day
            val currentMonth = bsDate.month
            val currentYear = bsDate.year

            // Set month header
            views.setTextViewText(R.id.tv_month_header, "${nepaliMonths[currentMonth - 1]} ${currentYear}")

            // Get first day of the month (which weekday it falls on)
            val firstDayOfMonth = getFirstDayOfMonth(currentYear, currentMonth)

            // Get total days in month
            val totalDays = getMonthDays(currentYear, currentMonth)

            // Clear all cells first
            for (week in 0..5) {
                for (dayOfWeek in 0..6) {
                    views.setTextViewText(dayCellIds[week][dayOfWeek], "")
                    views.setTextColor(dayCellIds[week][dayOfWeek], Color.parseColor("#CCCCCC"))
                    views.setInt(dayCellIds[week][dayOfWeek], "setBackgroundResource", 0)
                }
            }

            // Fill in the days
            var dayNum = 1
            for (week in 0..5) {
                for (dayOfWeek in 0..6) {
                    if (week == 0 && dayOfWeek < firstDayOfMonth) {
                        // Empty cell before first day
                        continue
                    }
                    if (dayNum > totalDays) {
                        // Past the last day
                        break
                    }

                    val cellId = dayCellIds[week][dayOfWeek]
                    views.setTextViewText(cellId, dayNum.toString())

                    // Highlight current day
                    if (dayNum == currentDay) {
                        views.setTextColor(cellId, Color.WHITE)
                        views.setInt(cellId, "setBackgroundResource", R.drawable.current_day_box)
                    } else if (dayOfWeek == 6 || isHoliday(currentYear, currentMonth, dayNum)) {
                        // Saturday or public holiday - red text
                        views.setTextColor(cellId, Color.parseColor("#FF9999"))
                    } else {
                        views.setTextColor(cellId, Color.parseColor("#CCCCCC"))
                    }

                    dayNum++
                }
            }

            // Set click to open calendar screen
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("nepalcivic://tools/nepali-calendar"))
            intent.setPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.month_widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun getFirstDayOfMonth(bsYear: Int, bsMonth: Int): Int {
            // Calculate which weekday the first day of the BS month falls on
            // We need to find the AD date for bsYear/bsMonth/1, then get its weekday

            // First, calculate total days from reference to the first of this month
            var totalDays = 0

            // Add days from reference year to target year
            for (y in refBsYear until bsYear) {
                for (m in 1..12) {
                    totalDays += getMonthDays(y, m)
                }
            }

            // Add days for months in target year up to (but not including) target month
            for (m in 1 until bsMonth) {
                totalDays += getMonthDays(bsYear, m)
            }

            // Subtract the days we were into the reference month
            totalDays -= (refBsDay - 1)

            // Reference date (2014-04-13) was a Sunday (day 0)
            val refDayOfWeek = 0 // Sunday

            val dayOfWeek = (refDayOfWeek + totalDays) % 7
            return if (dayOfWeek < 0) dayOfWeek + 7 else dayOfWeek
        }

        private fun adToBs(year: Int, month: Int, day: Int): BsDate {
            val totalDays = daysSinceReference(year, month, day)

            var bsYear = refBsYear
            var bsMonth = refBsMonth
            var bsDay = refBsDay + totalDays

            if (totalDays >= 0) {
                while (true) {
                    val monthDays = getMonthDays(bsYear, bsMonth)
                    if (bsDay <= monthDays) break

                    bsDay -= monthDays
                    bsMonth++
                    if (bsMonth > 12) {
                        bsMonth = 1
                        bsYear++
                    }
                }
            } else {
                bsDay = refBsDay + totalDays
                while (bsDay < 1) {
                    bsMonth--
                    if (bsMonth < 1) {
                        bsMonth = 12
                        bsYear--
                    }
                    bsDay += getMonthDays(bsYear, bsMonth)
                }
            }

            return BsDate(bsYear, bsMonth, bsDay)
        }

        private fun getMonthDays(year: Int, month: Int): Int {
            val monthDays = bsMonthDays[year]
            return if (monthDays != null) {
                monthDays[month - 1]
            } else {
                intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30)[month - 1]
            }
        }

        private fun isHoliday(year: Int, month: Int, day: Int): Boolean {
            return holidays[year]?.get(month)?.contains(day) == true
        }

        private fun daysSinceReference(year: Int, month: Int, day: Int): Int {
            val cal1 = Calendar.getInstance().apply {
                set(Calendar.YEAR, year)
                set(Calendar.MONTH, month - 1)
                set(Calendar.DAY_OF_MONTH, day)
                set(Calendar.HOUR_OF_DAY, 12)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val cal2 = Calendar.getInstance().apply {
                set(Calendar.YEAR, refAdYear)
                set(Calendar.MONTH, refAdMonth - 1)
                set(Calendar.DAY_OF_MONTH, refAdDay)
                set(Calendar.HOUR_OF_DAY, 12)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val diff = cal1.timeInMillis - cal2.timeInMillis
            return (diff / (1000L * 60 * 60 * 24)).toInt()
        }

        data class BsDate(val year: Int, val month: Int, val day: Int)
    }
}
