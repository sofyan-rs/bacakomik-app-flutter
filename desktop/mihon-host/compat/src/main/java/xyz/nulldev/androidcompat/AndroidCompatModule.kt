/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: registers the singletons with KoinGlobalHelper instead of Koin.
package xyz.nulldev.androidcompat

import android.content.Context
import xyz.nulldev.androidcompat.androidimpl.CustomContext
import xyz.nulldev.androidcompat.androidimpl.FakePackageManager
import xyz.nulldev.androidcompat.info.ApplicationInfoImpl
import xyz.nulldev.androidcompat.io.AndroidFiles
import xyz.nulldev.androidcompat.pm.PackageController
import xyz.nulldev.androidcompat.service.ServiceSupport
import xyz.nulldev.androidcompat.util.KoinGlobalHelper
import xyz.nulldev.ts.config.GlobalConfigManager

fun registerAndroidCompat() {
    KoinGlobalHelper.register(AndroidFiles::class.java) { AndroidFiles() }
    KoinGlobalHelper.register(ApplicationInfoImpl::class.java) { ApplicationInfoImpl(GlobalConfigManager) }
    KoinGlobalHelper.register(ServiceSupport::class.java) { ServiceSupport() }
    KoinGlobalHelper.register(FakePackageManager::class.java) { FakePackageManager() }
    KoinGlobalHelper.register(PackageController::class.java) { PackageController() }
    KoinGlobalHelper.register(CustomContext::class.java) { CustomContext() }
    KoinGlobalHelper.register(Context::class.java) { KoinGlobalHelper.instance(CustomContext::class.java) }
}
