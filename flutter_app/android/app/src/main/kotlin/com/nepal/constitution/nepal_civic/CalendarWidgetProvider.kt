package com.nepal.constitution.nepal_civic

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
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

            // Convert to BS (simplified - using approximate conversion)
            val bsDate = adToBs(year, month + 1, day)

            // Update views
            views.setTextViewText(R.id.tv_day, bsDate.day.toString())
            views.setTextViewText(R.id.tv_month_year, "${nepaliMonths[bsDate.month - 1]} ${bsDate.year}")
            views.setTextViewText(R.id.tv_weekday, nepaliWeekdays[weekday])
            views.setTextViewText(R.id.tv_english_date, "${englishMonths[month]} $day, $year")

            // Set click to open app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        // Simple AD to BS conversion (approximate)
        private fun adToBs(year: Int, month: Int, day: Int): BsDate {
            // Reference: 2000-01-01 AD = 2056-09-17 BS
            val refAdYear = 2000
            val refAdMonth = 1
            val refAdDay = 1
            val refBsYear = 2056
            val refBsMonth = 9
            val refBsDay = 17

            // Days in each BS month (approximate, varies by year)
            val bsMonthDays = intArrayOf(31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30)

            // Calculate days from reference
            val adDays = daysSinceReference(year, month, day, refAdYear, refAdMonth, refAdDay)

            // Add to BS reference
            var bsYear = refBsYear
            var bsMonth = refBsMonth
            var bsDay = refBsDay + adDays

            // Normalize
            while (bsDay > bsMonthDays[(bsMonth - 1) % 12]) {
                bsDay -= bsMonthDays[(bsMonth - 1) % 12]
                bsMonth++
                if (bsMonth > 12) {
                    bsMonth = 1
                    bsYear++
                }
            }
            while (bsDay < 1) {
                bsMonth--
                if (bsMonth < 1) {
                    bsMonth = 12
                    bsYear--
                }
                bsDay += bsMonthDays[(bsMonth - 1) % 12]
            }

            return BsDate(bsYear, bsMonth, bsDay)
        }

        private fun daysSinceReference(year: Int, month: Int, day: Int, refYear: Int, refMonth: Int, refDay: Int): Int {
            val cal1 = Calendar.getInstance().apply {
                set(year, month - 1, day)
            }
            val cal2 = Calendar.getInstance().apply {
                set(refYear, refMonth - 1, refDay)
            }
            val diff = cal1.timeInMillis - cal2.timeInMillis
            return (diff / (1000 * 60 * 60 * 24)).toInt()
        }

        data class BsDate(val year: Int, val month: Int, val day: Int)
    }
}
