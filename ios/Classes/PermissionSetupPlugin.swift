import Flutter
import UIKit

/// Reports the usage-description keys the app declares in Info.plist.
public class PermissionSetupPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "play_permission_setup/detector",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(PermissionSetupPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "declared" else {
      result(FlutterMethodNotImplemented)
      return
    }
    let info = Bundle.main.infoDictionary ?? [:]
    var keys: [String] = []
    for (key, value) in info {
      // Blank texts are ignored: Apple rejects them.
      if key.hasPrefix("NS"), key.hasSuffix("UsageDescription"),
        let text = value as? String,
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        keys.append(key)
      }
    }
    let modes = info["UIBackgroundModes"] as? [String] ?? []
    result(["platform": "ios", "keys": keys, "backgroundModes": modes])
  }
}
