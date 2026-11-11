/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: the folders of compat-reference.conf, under ApplicationRootDir.
package xyz.nulldev.androidcompat.config

import xyz.nulldev.ts.config.ApplicationRootDir
import xyz.nulldev.ts.config.ConfigModule

class FilesConfigModule(
    root: String = ApplicationRootDir,
) : ConfigModule() {
    val rootDir: String = "$root/appdata"
    val externalStorageDir: String = "$root/extappdata"
    val dataDir: String = "$rootDir/data"
    val filesDir: String = "$rootDir/files"
    val cacheDir: String = "$rootDir/cache"
    val codeCacheDir: String = "$rootDir/code_cache"
    val noBackupFilesDir: String = "$rootDir/no_backup"
    val databasesDir: String = "$rootDir/databases"
    val prefsDir: String = "$rootDir/shared_prefs"
    val externalFilesDirs: MutableList<String> = mutableListOf("$externalStorageDir/files")
    val obbDirs: MutableList<String> = mutableListOf("$externalStorageDir/obb")
    val externalCacheDirs: MutableList<String> = mutableListOf("$externalStorageDir/cache")
    val externalMediaDirs: MutableList<String> = mutableListOf("$externalStorageDir/media")
    val downloadCacheDir: String = "$externalStorageDir/downloadCache"
    val packageDir: String = "$root/android-compat/packages"
}
