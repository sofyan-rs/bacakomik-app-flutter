/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

package xyz.nulldev.androidcompat

import android.app.Application
import xyz.nulldev.androidcompat.androidimpl.CustomContext
import xyz.nulldev.androidcompat.util.KoinGlobalHelper

class AndroidCompat {
    val context: CustomContext by lazy { KoinGlobalHelper.instance(CustomContext::class.java) }

    fun startApp(application: Application) {
        application.attach(context)
        application.onCreate()
    }
}
