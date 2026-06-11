package com.example.safety;

import android.app.IntentService;
import android.content.Intent;
import android.util.Log;

import java.util.ArrayList;

/**
 * Enhanced SOS Dispatch Service.
 * Sends SMS to emergency contacts with location link.
 * Called from RokhokForegroundService when SOS is triggered.
 */
public class SMSDispatchService extends IntentService {

    private static final String TAG = "SMSDispatchService";

    public static final String EXTRA_CONTACTS  = "contacts";   // ArrayList<String> "name|phone"
    public static final String EXTRA_LATITUDE  = "latitude";
    public static final String EXTRA_LONGITUDE = "longitude";
    public static final String EXTRA_EVENT_ID  = "event_id";

    private LocalStorageManager storageManager;

    public SMSDispatchService() {
        super("SMSDispatchService");
    }

    @Override
    public void onCreate() {
        super.onCreate();
        storageManager = new LocalStorageManager(this);
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        if (intent == null) return;

        ArrayList<String> contacts = intent.getStringArrayListExtra(EXTRA_CONTACTS);
        double lat = intent.getDoubleExtra(EXTRA_LATITUDE, 0.0);
        double lng = intent.getDoubleExtra(EXTRA_LONGITUDE, 0.0);
        String eventId = intent.getStringExtra(EXTRA_EVENT_ID);

        if (contacts == null || contacts.isEmpty()) {
            Log.w(TAG, "No contacts to send SMS to");
            return;
        }

        String mapsLink = "https://maps.google.com/?q=" + lat + "," + lng;
        String message = buildSOSMessage(mapsLink);

        int sentCount = 0;
        for (String contact : contacts) {
            // Format: "name|+8801700000000"
            String[] parts = contact.split("\\|");
            if (parts.length < 2) continue;

            String name  = parts[0];
            String phone = parts[1];

            if (sendSMS(phone, message)) {
                sentCount++;
                Log.d(TAG, "SOS SMS sent to: " + name + " (" + phone + ")");
            } else {
                Log.w(TAG, "Failed to send SMS to: " + name);
            }
        }

        // Store result locally
        if (eventId != null && storageManager != null) {
            String details = String.format("SMS dispatched to %d/%d contacts", 
                sentCount, contacts.size());
            storageManager.logEventToFile(eventId, details);
        }
    }

    private String buildSOSMessage(String mapsLink) {
        return "🆘 EMERGENCY ALERT from Rokhok\n\n" +
                "I need help! This is an automated SOS.\n" +
                "My location: " + mapsLink + "\n\n" +
                "Please call me or contact emergency services immediately.";
    }

    /**
     * Send SMS and return success status
     */
    private boolean sendSMS(String phone, String message) {
        try {
            android.telephony.SmsManager smsManager = 
                android.telephony.SmsManager.getDefault();

            // Split long messages — SMS limit is 160 chars
            if (message.length() > 160) {
                ArrayList<String> parts = smsManager.divideMessage(message);
                smsManager.sendMultipartTextMessage(
                        phone, null, parts, null, null
                );
            } else {
                smsManager.sendTextMessage(phone, null, message, null, null);
            }
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Failed to send SMS to " + phone + ": " + e.getMessage());
            return false;
        }
    }
}