package com.example.klarna_flutter

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** KlarnaFlutterPlugin */
class KlarnaFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.NewIntentListener {
    
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var activityPluginBinding: ActivityPluginBinding? = null
    
    // Static listener to broadcast intents to views
    companion object {
        var newIntentListener: ((Intent) -> Boolean)? = null
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "klarna_flutter")
        channel.setMethodCallHandler(this)
        
        // Register the platform view factory for KlarnaPaymentView
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "klarna_flutter/payment_view",
            KlarnaPaymentViewFactory(
                messenger = flutterPluginBinding.binaryMessenger,
                activityProvider = { activity }
            )
        )
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        flutterPluginBinding = null
    }

    // ActivityAware implementation
    
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
        activity = binding.activity
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityPluginBinding?.removeOnNewIntentListener(this)
        activityPluginBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
        activity = binding.activity
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activityPluginBinding?.removeOnNewIntentListener(this)
        activityPluginBinding = null
        activity = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        return newIntentListener?.invoke(intent) ?: false
    }
}
