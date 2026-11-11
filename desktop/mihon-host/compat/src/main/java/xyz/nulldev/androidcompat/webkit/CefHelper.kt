/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: the desktop host sets cefApp (CefRuntime) when a source first
// opens a web view.
package xyz.nulldev.androidcompat.webkit

import android.util.Log
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.first
import org.cef.CefApp
import org.cef.CefClient


object CefHelper {
    val cefApp = MutableStateFlow<Result<CefApp?>>(Result.success(null))

    suspend fun createClient(): CefClient {
        val app = waitForInit().first()
        val client = app.createClient()
        JsHandler(client) // This adds itself to a global map
        return client
    }

    fun waitForInit() =
        callbackFlow {
            val app = cefApp.first { it.isFailure || it.getOrThrow() != null }.getOrThrow()!!
            app.onInitialization {
                Log.d("CefHelper", "CEF: Initialization state $it")
                when (it) {
                    CefApp.CefAppState.INITIALIZED -> {
                        trySend(app)
                        close()
                    }

                    CefApp.CefAppState.SHUTTING_DOWN, CefApp.CefAppState.TERMINATED -> {
                        close(CefException("Shutting down"))
                    }

                    else -> {}
                }
            }
            awaitClose {}
        }

    class CefException(
        msg: String,
    ) : Exception(msg)
}
