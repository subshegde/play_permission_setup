package com.permissionsetup;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * Reports the permissions the installed app declares (the merged manifest, so
 * permissions added by other plugins are included).
 */
public class PermissionSetupPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private Context context;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "play_permission_setup/detector");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        if (channel != null) channel.setMethodCallHandler(null);
        channel = null;
        context = null;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (!"declared".equals(call.method)) {
            result.notImplemented();
            return;
        }
        if (context == null) {
            result.error("no_context", "Plugin is not attached to an engine.", null);
            return;
        }
        try {
            PackageManager pm = context.getPackageManager();
            PackageInfo info;
            if (Build.VERSION.SDK_INT >= 33) {
                info = pm.getPackageInfo(
                        context.getPackageName(),
                        PackageManager.PackageInfoFlags.of((long) PackageManager.GET_PERMISSIONS));
            } else {
                info = pm.getPackageInfo(context.getPackageName(), PackageManager.GET_PERMISSIONS);
            }
            List<String> names = new ArrayList<>();
            if (info.requestedPermissions != null) {
                for (String p : info.requestedPermissions) {
                    if (p != null) names.add(p);
                }
            }
            Map<String, Object> out = new HashMap<>();
            out.put("platform", "android");
            out.put("sdkInt", Build.VERSION.SDK_INT);
            out.put("permissions", names);
            result.success(out);
        } catch (Exception e) {
            result.error("scan_failed", String.valueOf(e.getMessage()), null);
        }
    }
}
