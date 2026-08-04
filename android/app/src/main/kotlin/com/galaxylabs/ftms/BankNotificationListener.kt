package com.galaxylabs.ftms

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.Log

object BankNotificationBridge {
    var sink: io.flutter.plugin.common.EventChannel.EventSink? = null
    fun post(app: String, title: String, text: String) {
        val payload = mapOf(
            "app" to app,
            "title" to title,
            "text" to text
        )
        try {
            sink?.success(payload)
        } catch (e: Exception) {
            Log.e("RideKSA", "BankNotificationBridge post failed: ${e.message}")
        }
    }
}

class BankNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getString(Notification.EXTRA_TEXT) ?: ""
        val subText = extras.getString(Notification.EXTRA_SUB_TEXT) ?: ""
        val content = "$title $subText $text"
        if (content.isBlank()) return
        if (!isPaymentContent(content)) return
        BankNotificationBridge.post(sbn.packageName, title, text)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {}

    private fun isPaymentContent(content: String): Boolean {
        val keywords = listOf(
            "transfer", "transferred", "credited", "credit", "debit",
            "payment received", "money received", "incoming transfer",
            "transaction", "beneficiary", "SAR", "SR ", "ر.س", "رس",
            "تحويل", "تم التحويل", "إيداع", "خصم", "دائن", "مدين",
            "سداد", "المدفوعات", "استلام", "مستلم", "أموال",
            "bank", "sadad", "mada", "pay", "paid"
        )
        return keywords.any { content.contains(it, ignoreCase = true) }
    }
}
