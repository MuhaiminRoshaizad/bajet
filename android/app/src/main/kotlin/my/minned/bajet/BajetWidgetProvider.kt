package my.minned.bajet

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The home-screen widget: what is left of the week and buttons that open the
 * logger, empty or filled in from a favourite. It never logs on its own; the
 * owner still presses Log in the app. The data comes from the Flutter side
 * through home_widget, under the keys written by PlatformHomeSurface.
 */
class BajetWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { id ->
      val views = RemoteViews(context.packageName, R.layout.bajet_widget).apply {
        setTextViewText(R.id.week_line, widgetData.getString("week_line", null) ?: context.getString(R.string.widget_empty))
        setOnClickPendingIntent(R.id.widget_root, open(context, null))
        setOnClickPendingIntent(R.id.log_button, open(context, "bajet://log"))
        favourite(context, widgetData, this, 1, R.id.fav1_button)
        favourite(context, widgetData, this, 2, R.id.fav2_button)
      }
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  private fun favourite(context: Context, data: SharedPreferences, views: RemoteViews, n: Int, viewId: Int) {
    val label = data.getString("fav${n}_label", null)
    val link = data.getString("fav${n}_link", null)
    if (label == null || link == null) {
      views.setViewVisibility(viewId, View.GONE)
      return
    }
    views.setViewVisibility(viewId, View.VISIBLE)
    views.setTextViewText(viewId, label)
    views.setOnClickPendingIntent(viewId, open(context, link))
  }

  private fun open(context: Context, link: String?) =
      HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, link?.let(Uri::parse))
}
