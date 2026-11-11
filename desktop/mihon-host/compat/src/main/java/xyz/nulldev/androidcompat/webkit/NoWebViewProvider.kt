/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: a web view that cannot load anything (the browser it needs is
// not there yet, see the desktop host's CefRuntime): every call says why.
package xyz.nulldev.androidcompat.webkit

import android.webkit.WebView
import android.webkit.WebViewProvider
import java.lang.reflect.Proxy

object NoWebViewProvider {
    fun create(
        view: WebView,
        message: String =
            "This source runs the site in Android's web view, which SCANCORE on this computer " +
                "cannot offer. It works in SCANCORE for Android.",
    ): WebViewProvider =
        Proxy.newProxyInstance(WebViewProvider::class.java.classLoader, arrayOf(WebViewProvider::class.java)) { _, method, _ ->
            when (method.name) {
                "toString" -> "NoWebViewProvider"
                "hashCode" -> view.hashCode()
                "equals" -> false
                else -> throw UnsupportedOperationException(message)
            }
        } as WebViewProvider
}
