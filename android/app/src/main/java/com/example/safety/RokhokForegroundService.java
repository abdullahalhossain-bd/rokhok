package com.example.safety;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;


import java.io.File;
import java.util.ArrayList;

/**
 * Main Rokhok SOS Foreground Service.
 * Orchestrates all SOS sub-services:
 *   - SMS dispatch
 *   - Location tracking
 *   - Video recording
 *   - Bluetooth broadcasting
 *   - Local storage
 *
 * FIXES APPLIED:
 *   1. handleStopSOS() double-call prevented via `running` guard
 *   2. `running` is now instance-level logic with proper reset on process restart
 *   3. intent == null (START_STICKY restart) handled gracefully — stops orphaned services
 *   4. getApplicationContext() used instead of `this` in VideoRecorder
 *   5. File existence check before saving video metadata
 *   6. VideoRecorder and BluetoothBroadcaster released inside handleStopSOS()
 */
public class RokhokForegroundService extends Service {

    private static final String TAG = "RokhokForegroundService";

    public static final String ACTION_START_SOS  = "START_SOS";
    public static final String ACTION_STOP_SOS   = "STOP_SOS";

    public static final String EXTRA_EVENT_ID  = "event_id";
    public static final String EXTRA_LATITUDE  = "latitude";
    public static final String EXTRA_LONGITUDE = "longitude";
    public static final String EXTRA_CONTACTS  = "contacts";

    private static final String CHANNEL_ID    = "rokhok_sos_channel";
    private static final int    NOTIFICATION_ID = 1001;

    // FIX 1 & 2: Use instance variable instead of static boolean.
    // Static `running` survives process restarts but instance state does not,
    // causing stale `true` values. Instance variable resets correctly.
    private boolean running = false;

    // Sub-service instances
    private VideoRecorder      videoRecorder;
    private LocalStorageManager storageManager;
    private BluetoothBroadcaster bluetoothBroadcaster;

    private String currentEventId;
    private double currentLatitude;
    private double currentLongitude;

    /**
     * Static helper — safe to call from outside. Returns false if the
     * service process is not alive (instance variable approach via a
     * lightweight static flag that is explicitly cleared on stop/destroy).
     */
    private static boolean staticRunning = false;

    public static boolean isRunning(android.content.Context context) {
        return staticRunning;
    }

    // ─────────────────────────────────────────────
    // Lifecycle
    // ─────────────────────────────────────────────

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        // FIX 4: Always use application context for long-lived objects
        videoRecorder        = new VideoRecorder();
        storageManager       = new LocalStorageManager(getApplicationContext());
        bluetoothBroadcaster = new BluetoothBroadcaster(getApplicationContext());
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {

        // FIX 3: Handle null intent (system restart via START_STICKY)
        // If the service is restarted by the OS without a valid intent,
        // we cannot resume SOS safely — stop any orphaned sub-services and exit.
        if (intent == null) {
            Log.w(TAG, "Restarted by OS with null intent — cleaning up orphaned state.");
            stopOrphanedSubServices();
            stopSelf();
            return START_NOT_STICKY; // Don't restart again without an explicit caller
        }

        String action = intent.getAction();

        if (ACTION_START_SOS.equals(action)) {
            handleStartSOS(intent);
        } else if (ACTION_STOP_SOS.equals(action)) {
            handleStopSOS();
        }

        return START_STICKY;
    }

    // ─────────────────────────────────────────────
    // SOS Handlers
    // ─────────────────────────────────────────────

    /**
     * Handle START_SOS action.
     */
    private void handleStartSOS(Intent intent) {
        if (running) {
            Log.w(TAG, "SOS already running — ignoring duplicate START_SOS.");
            return;
        }

        startForeground(NOTIFICATION_ID, buildNotification());

        currentEventId  = intent.getStringExtra(EXTRA_EVENT_ID);
        currentLatitude  = intent.getDoubleExtra(EXTRA_LATITUDE, 0);
        currentLongitude = intent.getDoubleExtra(EXTRA_LONGITUDE, 0);
        ArrayList<String> contacts = intent.getStringArrayListExtra(EXTRA_CONTACTS);

        running       = true;
        staticRunning = true;

        Log.d(TAG, "SOS started: " + currentEventId);

        // 1️⃣ Vibration feedback
        VibrationHelper.vibrateSOS(this);

        // 2️⃣ Save to local storage
        if (storageManager != null) {
            storageManager.saveSOSEvent(
                    currentEventId,
                    String.valueOf(System.currentTimeMillis()),
                    currentLatitude,
                    currentLongitude,
                    "active"
            );
            storageManager.logEventToFile(currentEventId, "SOS Triggered");
        }

        // 3️⃣ Start location tracking service
        Intent locationIntent = new Intent(this, LocationTrackingService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(locationIntent);
        } else {
            startService(locationIntent);
        }

        // 4️⃣ Dispatch SMS to contacts
        Intent smsIntent = new Intent(this, SMSDispatchService.class);
        smsIntent.putExtra(SMSDispatchService.EXTRA_EVENT_ID,  currentEventId);
        smsIntent.putExtra(SMSDispatchService.EXTRA_LATITUDE,  currentLatitude);
        smsIntent.putExtra(SMSDispatchService.EXTRA_LONGITUDE, currentLongitude);
        smsIntent.putStringArrayListExtra(SMSDispatchService.EXTRA_CONTACTS, contacts);
        startService(smsIntent);

        // 5️⃣ Start video recording (silent, background)
        // FIX 4: Pass ApplicationContext — avoids Service context leak
        if (videoRecorder != null) {
            videoRecorder.startRecording(getApplicationContext());
            Log.d(TAG, "Video recording started");
        }

        // 6️⃣ Start Bluetooth broadcasting (nearby alert)
        if (bluetoothBroadcaster != null) {
            bluetoothBroadcaster.startBroadcasting(currentEventId);
            Log.d(TAG, "Bluetooth broadcasting started");
        }
    }

    /**
     * Handle STOP_SOS action.
     * FIX 1: Guard with `running` flag — safe to call multiple times.
     */
    private void handleStopSOS() {
        if (!running) {
            Log.w(TAG, "handleStopSOS called but SOS is not running — skipping.");
            return;
        }

        Log.d(TAG, "SOS stopped: " + currentEventId);

        running       = false;
        staticRunning = false;

        // Stop & save video recording
        if (videoRecorder != null) {
            String videoPath = videoRecorder.stopRecording();

            // FIX 5: Validate file exists and has content before saving metadata
            if (videoPath != null) {
                File videoFile = new File(videoPath);
                if (videoFile.exists() && videoFile.length() > 0) {
                    if (storageManager != null) {
                        storageManager.saveVideoRecording(
                                currentEventId,
                                videoPath,
                                videoFile.length()
                        );
                        Log.d(TAG, "Video saved: " + videoPath + " (" + videoFile.length() + " bytes)");
                    }
                } else {
                    Log.w(TAG, "Video file missing or empty: " + videoPath);
                }
            }

            // FIX 6: Release VideoRecorder resources here (not just in onDestroy)
            videoRecorder.release();
            videoRecorder = null;
        }

        // Stop Bluetooth broadcasting
        if (bluetoothBroadcaster != null) {
            bluetoothBroadcaster.stopBroadcasting();
            // FIX 6: Release BluetoothBroadcaster resources here
            bluetoothBroadcaster.release();
            bluetoothBroadcaster = null;
        }

        // Stop location tracking
        stopService(new Intent(this, LocationTrackingService.class));

        // Update local storage — mark event resolved
        if (storageManager != null) {
            storageManager.saveSOSEvent(
                    currentEventId,
                    String.valueOf(System.currentTimeMillis()),
                    currentLatitude,
                    currentLongitude,
                    "resolved"
            );
            storageManager.logEventToFile(currentEventId, "SOS Cancelled/Resolved");
        }

        stopForeground(STOP_FOREGROUND_REMOVE);
        stopSelf();
    }

    /**
     * FIX 3: Stop sub-services when restarted with null intent.
     * Prevents orphaned location/SMS services from running indefinitely.
     */
    private void stopOrphanedSubServices() {
        try {
            stopService(new Intent(this, LocationTrackingService.class));
            stopService(new Intent(this, SMSDispatchService.class));
            if (videoRecorder != null) {
                videoRecorder.stopRecording();
                videoRecorder.release();
                videoRecorder = null;
            }
            if (bluetoothBroadcaster != null) {
                bluetoothBroadcaster.stopBroadcasting();
                bluetoothBroadcaster.release();
                bluetoothBroadcaster = null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error cleaning up orphaned sub-services", e);
        }
        staticRunning = false;
    }

    // ─────────────────────────────────────────────
    // Notification
    // ─────────────────────────────────────────────

    private Notification buildNotification() {
        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Rokhok SOS Active")
                .setContentText("Emergency protection is running")
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setOngoing(true)
                .build();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "Rokhok SOS",
                    NotificationManager.IMPORTANCE_HIGH
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    // ─────────────────────────────────────────────
    // Destroy
    // ─────────────────────────────────────────────

    @Override
    public void onDestroy() {
        // FIX 1: Guard prevents double execution of stop logic
        // handleStopSOS() internally checks `running` before doing anything
        handleStopSOS();

        // Safety net: release any remaining resources not yet nulled out
        if (videoRecorder != null) {
            videoRecorder.release();
            videoRecorder = null;
        }
        if (bluetoothBroadcaster != null) {
            bluetoothBroadcaster.release();
            bluetoothBroadcaster = null;
        }

        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}