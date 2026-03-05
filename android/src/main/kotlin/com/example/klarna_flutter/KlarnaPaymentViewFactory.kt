package com.example.klarna_flutter

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Factory for creating KlarnaPlatformView instances.
 * This factory is registered with Flutter to create native Klarna payment views.
 */
class KlarnaPaymentViewFactory(
    private val messenger: BinaryMessenger,
    private val activityProvider: () -> Activity?
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any?>
        return KlarnaPlatformView(
            context = context,
            viewId = viewId,
            messenger = messenger,
            creationParams = creationParams,
            activityProvider = activityProvider
        )
    }
}
