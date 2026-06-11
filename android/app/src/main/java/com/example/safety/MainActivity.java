package com.example.safety;

import android.content.Intent;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Main Flutter Activity with MethodChannel + EventChannel bridges to native Android services.
 * Handles SOS trigger, location streaming, permissions, and vibration feedback.
 */
public class MainActivity extends FlutterActivity {

    private static final String TAG = "MainActivity";

    // MethodChannel names (must match Dart side exactly)
    private static final String SOS_CHANNEL      = "com.rokhok.app/sos";
    private static final String LOCATION_CHANNEL = "com.rokhok.app/location";
    private static final String VIBRATION_CHANNEL = "com.rokhok.app/vibration";
    
    // EventChannel for location stream
    private static final String LOCATION_STREAM  = "com.rokhok.app/location/stream";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // ── SOS MethodChannel ──────────────────────────────────────
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                SOS_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            try {
                switch (call.method) {

                    case "startSOS": {
                        String eventId   = call.argument("eventId");
                        double latitude  = call.<Double>argument("latitude");
                        double longitude = call.<Double>argument("longitude");
                        List<Map<String, String>> contactMaps = call.argument("contacts");

                        // Convert contacts to "name|phone" strings
                        ArrayList<String> contacts = new ArrayList<>();
                        if (contactMaps != null) {
                            for (Map<String, String> c : contactMaps) {
                                contacts.add(c.get("name") + "|" + c.get("phone"));
                            }
                        }

                        Intent intent = new Intent(this, RokhokForegroundService.class);
                        intent.setAction(RokhokForegroundService.ACTION_START_SOS);
                        intent.putExtra(RokhokForegroundService.EXTRA_EVENT_ID, eventId);
                        intent.putExtra(RokhokForegroundService.EXTRA_LATITUDE, latitude);
                        intent.putExtra(RokhokForegroundService.EXTRA_LONGITUDE, longitude);
                        intent.putStringArrayListExtra(
                                RokhokForegroundService.EXTRA_CONTACTS, contacts);

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent);
                        } else {
                            startService(intent);
                        }

                        result.success(null);
                        Log.d(TAG, "SOS started: " + eventId);
                        break;
                    }

                    case "stopSOS": {
                        Intent intent = new Intent(this, RokhokForegroundService.class);
                        intent.setAction(RokhokForegroundService.ACTION_STOP_SOS);
                        startService(intent);
                        result.success(null);
                        Log.d(TAG, "SOS stopped");
                        break;
                    }

                    case "isSOSActive": {
                        boolean active = RokhokForegroundService.isRunning(this);
                        result.success(active);
                        break;
                    }

                    case "getUploadedVideoUrl": {
                        String eventId = call.argument("eventId");
                        LocalStorageManager storage = new LocalStorageManager(getApplicationContext());
                        String url = storage.getUploadedVideoUrl(eventId);
                        result.success(url);
                        break;
                    }

                    case "sendTestSMS": {
                        String phone = call.argument("phone");
                        String name  = call.argument("name");
                        ArrayList<String> contacts = new ArrayList<>();
                        contacts.add(name + "|" + phone);

                        Intent intent = new Intent(this, SMSDispatchService.class);
                        intent.putStringArrayListExtra(
                                SMSDispatchService.EXTRA_CONTACTS, contacts);
                        intent.putExtra(SMSDispatchService.EXTRA_LATITUDE, 0.0);
                        intent.putExtra(SMSDispatchService.EXTRA_LONGITUDE, 0.0);
                        startService(intent);
                        result.success(null);
                        break;
                    }

                    default:
                        result.notImplemented();
                }
            } catch (Exception e) {
                Log.e(TAG, "Error in SOS MethodChannel", e);
                result.error("ERROR", e.getMessage(), null);
            }
        });

        // ── Vibration MethodChannel ───────────────────────────────
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                VIBRATION_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            try {
                switch (call.method) {
                    case "vibrate": {
                        String type = call.argument("type"); // light, medium, heavy, sos
                        switch (type) {
                            case "light":
                                VibrationHelper.vibrateLight(this);
                                break;
                            case "medium":
                                VibrationHelper.vibrateMedium(this);
                                break;
                            case "heavy":
                                VibrationHelper.vibrateHeavy(this);
                                break;
                            case "sos":
                                VibrationHelper.vibrateSOS(this);
                                break;
                        }
                        result.success(null);
                        break;
                    }
                    default:
                        result.notImplemented();
                }
            } catch (Exception e) {
                Log.e(TAG, "Error in Vibration MethodChannel", e);
                result.error("ERROR", e.getMessage(), null);
            }
        });

        // ── Location MethodChannel ────────────────────────────────
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                LOCATION_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            try {
                switch (call.method) {

                    case "getCurrentLocation":
                        LocationTrackingService.getCurrentLocation(
                                this,
                                location -> result.success(location),
                                error -> result.error("LOCATION_ERROR", error, null)
                        );
                        break;

                    case "requestPermissions":
                        result.success(true);
                        break;

                    default:
                        result.notImplemented();
                }
            } catch (Exception e) {
                Log.e(TAG, "Error in Location MethodChannel", e);
                result.error("ERROR", e.getMessage(), null);
            }
        });

        // ── Location EventChannel (stream) ────────────────────────
        new EventChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                LOCATION_STREAM
        ).setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                LocationTrackingService.setEventSink(events);
                Log.d(TAG, "Location stream subscribed");
            }

            @Override
            public void onCancel(Object arguments) {
                LocationTrackingService.setEventSink(null);
                Log.d(TAG, "Location stream cancelled");
            }
        });
    }
}