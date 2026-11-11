/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: no embedded browser (Cloudflare checks pass in SCANCORE's own
// window and arrive as cookies), and config set in code.
package xyz.nulldev.androidcompat

import xyz.nulldev.androidcompat.config.ApplicationInfoConfigModule
import xyz.nulldev.androidcompat.config.FilesConfigModule
import xyz.nulldev.androidcompat.config.SystemConfigModule
import xyz.nulldev.androidcompat.webkit.NoWebViewProvider
import android.webkit.WebView
import xyz.nulldev.ts.config.GlobalConfigManager

class AndroidCompatInitializer {
    fun init(userAgent: String) {
        GlobalConfigManager.registerModules(
            FilesConfigModule(),
            ApplicationInfoConfigModule(),
            SystemConfigModule(),
        )
        registerAndroidCompat()
        WebView.setProviderFactory { view: WebView -> NoWebViewProvider.create(view) }
        // Set some properties extensions use
        System.setProperty("http.agent", userAgent)
    }
}
