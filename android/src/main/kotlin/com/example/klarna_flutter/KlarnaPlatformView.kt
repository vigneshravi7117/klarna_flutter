package com.example.klarna_flutter

import android.app.Activity
import android.content.Context
import android.view.View
import android.widget.FrameLayout
import com.klarna.mobile.sdk.api.payments.KlarnaPaymentView
import com.klarna.mobile.sdk.api.payments.KlarnaPaymentViewCallback
import com.klarna.mobile.sdk.api.payments.KlarnaPaymentsSDKError
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import android.content.Intent

/**
 * Platform view that wraps KlarnaPaymentView for Flutter integration.
 * Handles all communication between Flutter and the native Klarna SDK.
 */
class KlarnaPlatformView(
    private val context: Context,
    private val viewId: Int,
    messenger: BinaryMessenger,
    creationParams: Map<String, Any?>?,
    private val activityProvider: () -> Activity?
) : PlatformView, MethodChannel.MethodCallHandler, KlarnaPaymentViewCallback {

    private val methodChannel: MethodChannel
    private val containerView: FrameLayout
    private var klarnaPaymentView: KlarnaPaymentView? = null
    
    private val category: String
    private val returnUrl: String?

    init {
        // Create method channel for this specific view instance
        methodChannel = MethodChannel(messenger, "klarna_flutter/payment_view_$viewId")
        methodChannel.setMethodCallHandler(this)

        // Extract creation parameters
        category = creationParams?.get("category") as? String ?: "klarna"
        returnUrl = creationParams?.get("returnUrl") as? String

        // Create container view
        containerView = FrameLayout(context)
        
        // Listen to new intents from the MainActivity
        KlarnaFlutterPlugin.newIntentListener = { intent ->
            handleNewIntent(intent)
        }

        // Initialize Klarna payment view
        initializeKlarnaView()
    }

    private fun initializeKlarnaView() {
        val activity = activityProvider()
        if (activity == null) {
            sendError("ACTIVITY_NOT_FOUND", "Activity not available", null)
            return
        }

        try {
            klarnaPaymentView = if (returnUrl != null) {
                KlarnaPaymentView(
                    context = activity,
                    category = category,
                    callback = this,
                    returnURL = returnUrl
                )
            } else {
                KlarnaPaymentView(
                    context = activity,
                    category = category,
                    callback = this
                )
            }

            klarnaPaymentView?.let { view ->
                view.layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT
                )
                containerView.addView(view)
            }
        } catch (e: Exception) {
            sendError("INITIALIZATION_ERROR", "Failed to create KlarnaPaymentView: ${e.message}", null)
        }
    }

    override fun getView(): View = containerView

    override fun dispose() {
        KlarnaFlutterPlugin.newIntentListener = null
        methodChannel.setMethodCallHandler(null)
        klarnaPaymentView = null
        containerView.removeAllViews()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val clientToken = call.argument<String>("clientToken")
                if (clientToken == null) {
                    result.error("INVALID_ARGUMENT", "clientToken is required", null)
                    return
                }
                initialize(clientToken, result)
            }
            "load" -> {
                val sessionData = call.argument<String>("sessionData")
                load(sessionData, result)
            }
            "authorize" -> {
                val sessionData = call.argument<String>("sessionData")
                val autoFinalize = call.argument<Boolean>("autoFinalize") ?: true
                authorize(sessionData, autoFinalize, result)
            }
            "reauthorize" -> {
                val sessionData = call.argument<String>("sessionData")
                reauthorize(sessionData, result)
            }
            "finalize" -> {
                val sessionData = call.argument<String>("sessionData")
                finalize(sessionData, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleNewIntent(intent: Intent): Boolean {
        if (intent.data?.scheme == returnUrl?.substringBefore("://")) {
            // Unclear if Klarna's SDK requires manual resumption on Android.
            // But normally, SDK handles onResume. Just in case there is a deep link API.
        }
        return false
    }

    private fun initialize(clientToken: String, result: MethodChannel.Result) {
        val view = klarnaPaymentView
        if (view == null) {
            result.error("VIEW_NOT_INITIALIZED", "KlarnaPaymentView not initialized", null)
            return
        }
        try {
            view.initialize(clientToken)
            result.success(null)
        } catch (e: Exception) {
            result.error("INITIALIZE_ERROR", e.message, null)
        }
    }

    private fun load(sessionData: String?, result: MethodChannel.Result) {
        val view = klarnaPaymentView
        if (view == null) {
            result.error("VIEW_NOT_INITIALIZED", "KlarnaPaymentView not initialized", null)
            return
        }
        try {
            view.load(sessionData)
            result.success(null)
        } catch (e: Exception) {
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    private fun authorize(sessionData: String?, autoFinalize: Boolean, result: MethodChannel.Result) {
        val view = klarnaPaymentView
        if (view == null) {
            result.error("VIEW_NOT_INITIALIZED", "KlarnaPaymentView not initialized", null)
            return
        }
        try {
            view.authorize(autoFinalize, sessionData)
            result.success(null)
        } catch (e: Exception) {
            result.error("AUTHORIZE_ERROR", e.message, null)
        }
    }

    private fun reauthorize(sessionData: String?, result: MethodChannel.Result) {
        val view = klarnaPaymentView
        if (view == null) {
            result.error("VIEW_NOT_INITIALIZED", "KlarnaPaymentView not initialized", null)
            return
        }
        try {
            view.reauthorize(sessionData)
            result.success(null)
        } catch (e: Exception) {
            result.error("REAUTHORIZE_ERROR", e.message, null)
        }
    }

    private fun finalize(sessionData: String?, result: MethodChannel.Result) {
        val view = klarnaPaymentView
        if (view == null) {
            result.error("VIEW_NOT_INITIALIZED", "KlarnaPaymentView not initialized", null)
            return
        }
        try {
            view.finalize(sessionData)
            result.success(null)
        } catch (e: Exception) {
            result.error("FINALIZE_ERROR", e.message, null)
        }
    }

    // KlarnaPaymentViewCallback implementations

    override fun onInitialized(view: KlarnaPaymentView) {
        methodChannel.invokeMethod("onInitialized", null)
    }

    override fun onLoaded(view: KlarnaPaymentView) {
        methodChannel.invokeMethod("onLoaded", null)
    }

    override fun onLoadPaymentReview(view: KlarnaPaymentView, showForm: Boolean) {
        methodChannel.invokeMethod("onLoadPaymentReview", mapOf("showForm" to showForm))
    }

    override fun onAuthorized(
        view: KlarnaPaymentView,
        approved: Boolean,
        authToken: String?,
        finalizeRequired: Boolean?
    ) {
        methodChannel.invokeMethod(
            "onAuthorized",
            mapOf(
                "approved" to approved,
                "authToken" to authToken,
                "finalizeRequired" to finalizeRequired
            )
        )
    }

    override fun onReauthorized(
        view: KlarnaPaymentView,
        approved: Boolean,
        authToken: String?
    ) {
        methodChannel.invokeMethod(
            "onReauthorized",
            mapOf(
                "approved" to approved,
                "authToken" to authToken
            )
        )
    }

    override fun onFinalized(
        view: KlarnaPaymentView,
        approved: Boolean,
        authToken: String?
    ) {
        methodChannel.invokeMethod(
            "onFinalized",
            mapOf(
                "approved" to approved,
                "authToken" to authToken
            )
        )
    }

    override fun onErrorOccurred(view: KlarnaPaymentView, error: KlarnaPaymentsSDKError) {
        methodChannel.invokeMethod(
            "onErrorOccurred",
            mapOf(
                "name" to error.name,
                "message" to error.message,
                "isFatal" to error.isFatal
            )
        )
    }

    private fun sendError(code: String, message: String, details: Any?) {
        methodChannel.invokeMethod(
            "onErrorOccurred",
            mapOf(
                "name" to code,
                "message" to message,
                "isFatal" to true
            )
        )
    }
}
