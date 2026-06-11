// android/app/src/main/java/com/rokhok/services/SMSDispatchService.java
// Sends emergency SMS to all contacts using Android SmsManager.
// WHY NATIVE SMS (not Twilio/API)?
//   1. Works offline — no internet needed during an emergency
//   2. Delivers even on 2G networks
//   3. No backend cost per message
//   4. Faster — no HTTP round trip

package com.rokhok.services;

import android.app.IntentService;
import android.content.Intent;
import android.telephony.SmsManager;
import android.util.Log;

import java.util.ArrayList;

public class SMSDispatchService extends IntentService {

    private static final String TAG = "SMSDispatchService";

    public static final String EXTRA_CONTACTS  = "contacts";   // ArrayList<String> "name|phone"
    public static final String EXTRA_LATITUDE  = "latitude";
    public static final String EXTRA_LONGITUDE = "longitude";

    public SMSDispatchService() {
        super("SMSDispatchService");
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        if (intent == null) return;

        ArrayList<String> contacts = intent.getStringArrayListExtra(EXTRA_CONTACTS);
        double lat = intent.getDoubleExtra(EXTRA_LATITUDE, 0.0);
        double lng = intent.getDoubleExtra(EXTRA_LONGITUDE, 0.0);

        if (contacts == null || contacts.isEmpty()) {
            Log.w(TAG, "No contacts to send SMS to");
            return;
        }

        String mapsLink = "https://maps.google.com/?q=" + lat + "," + lng;
        String message = buildSOSMessage(mapsLink);

        for (String contact : contacts) {
            // Format: "name|+8801700000000"
            String[] parts = contact.split("\\|");
            if (parts.length < 2) continue;

            String name  = parts[0];
            String phone = parts[1];

            sendSMS(phone, message);
            Log.d(TAG, "SOS SMS sent to: " + name + " (" + phone + ")");
        }
    }

    private String buildSOSMessage(String mapsLink) {
        return "🆘 EMERGENCY ALERT from Rokhok\n\n" +
                "I need help! This is an automated SOS.\n" +
                "My location: " + mapsLink + "\n\n" +
                "Please call me or contact emergency services immediately.";
    }

    private void sendSMS(String phone, String message) {
        try {
            SmsManager smsManager = SmsManager.getDefault();

            // Split long messages — SMS limit is 160 chars
            if (message.length() > 160) {
                ArrayList<String> parts = smsManager.divideMessage(message);
                smsManager.sendMultipartTextMessage(
                        phone, null, parts, null, null
                );
            } else {
                smsManager.sendTextMessage(phone, null, message, null, null);
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to send SMS to " + phone + ": " + e.getMessage());
            // ⚠️ Common failure reason: SEND_SMS permission not granted.
            // Handled at Dart side via permission_handler before triggering SOS.
        }
    }
}