package com.nepal.constitution.nepal_civic

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import java.util.Calendar

class CalendarWidgetProvider : AppWidgetProvider() {

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

        // Nepali weekday names
        private val nepaliWeekdays = arrayOf(
            "आइतबार", "सोमबार", "मंगलबार", "बुधबार", "बिहीबार", "शुक्रबार", "शनिबार"
        )

        // English month names
        private val englishMonths = arrayOf(
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        )

        // BS month days for years 2070-2090 (actual calendar data)
        // Each array: [Baisakh, Jestha, Ashadh, Shrawan, Bhadra, Ashwin, Kartik, Mangsir, Poush, Magh, Falgun, Chaitra]
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

        // Reference date: 2014-04-13 AD = 2071-01-01 BS (Baisakh 1, 2071)
        private val refAdYear = 2014
        private val refAdMonth = 4
        private val refAdDay = 13
        private val refBsYear = 2071
        private val refBsMonth = 1
        private val refBsDay = 1

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.calendar_widget)

            // Get current date
            val cal = Calendar.getInstance()
            val year = cal.get(Calendar.YEAR)
            val month = cal.get(Calendar.MONTH)
            val day = cal.get(Calendar.DAY_OF_MONTH)
            val weekday = cal.get(Calendar.DAY_OF_WEEK) - 1 // 0 = Sunday

            // Convert to BS
            val bsDate = adToBs(year, month + 1, day)

            // Update views
            views.setTextViewText(R.id.tv_day, bsDate.day.toString())
            views.setTextViewText(R.id.tv_month_year, "${nepaliMonths[bsDate.month - 1]} ${bsDate.year}")
            views.setTextViewText(R.id.tv_weekday, nepaliWeekdays[weekday])
            views.setTextViewText(R.id.tv_english_date, "${englishMonths[month]} $day, $year")

            // Set click to open calendar screen
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("nepalcivic://tools/nepali-calendar"))
            intent.setPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun adToBs(year: Int, month: Int, day: Int): BsDate {
            // Calculate days from reference date
            val totalDays = daysSinceReference(year, month, day)

            var bsYear = refBsYear
            var bsMonth = refBsMonth
            var bsDay = refBsDay + totalDays

            if (totalDays >= 0) {
                // Forward from reference
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
                // Backward from reference
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
                // Fallback for years outside our data
                intArrayOf(31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30)[month - 1]
            }
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
