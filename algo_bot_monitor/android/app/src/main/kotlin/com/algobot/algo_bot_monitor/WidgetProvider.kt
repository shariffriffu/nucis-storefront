package com.algobot.algo_bot_monitor

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class WidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs: SharedPreferences = context.getSharedPreferences("HomeWidgetSharedPreferences", Context.MODE_PRIVATE)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val pnl = prefs.getString("pnl", "0.00")
            val balance = prefs.getString("balance", "0.00")
            val lastTrade = prefs.getString("lastTrade", "No Trades Yet")
            val runningStatus = prefs.getString("runningStatus", "STOPPED")

            // Format P&L output text and text color
            val isNegative = pnl != null && pnl.startsWith("-")
            val cleanPnl = pnl?.replace("-", "")?.replace("+", "") ?: "0.00"
            val pnlFormatted = if (isNegative) {
                "-\$$cleanPnl"
            } else {
                "+\$$cleanPnl"
            }

            views.setTextViewText(R.id.widget_pnl, pnlFormatted)
            if (isNegative) {
                views.setTextColor(R.id.widget_pnl, android.graphics.Color.parseColor("#FF5252")) // Material 3 Crimson Red
            } else {
                views.setTextColor(R.id.widget_pnl, android.graphics.Color.parseColor("#00E676")) // Material 3 Emerald Green
            }

            views.setTextViewText(R.id.widget_balance, "\$$balance")
            views.setTextViewText(R.id.widget_last_trade, lastTrade)
            views.setTextViewText(R.id.widget_status, runningStatus)

            // Format status badge colors
            if (runningStatus == "RUNNING") {
                views.setTextColor(R.id.widget_status, android.graphics.Color.parseColor("#00E676"))
            } else {
                views.setTextColor(R.id.widget_status, android.graphics.Color.parseColor("#FF5252"))
            }

            // Launch MainActivity when widget is tapped
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_pnl, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
