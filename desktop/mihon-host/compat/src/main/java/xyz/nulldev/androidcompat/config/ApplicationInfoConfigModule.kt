/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: fixed values instead of a config file. Extensions see the
// package name Mihon has.
package xyz.nulldev.androidcompat.config

import xyz.nulldev.ts.config.ConfigModule

class ApplicationInfoConfigModule(
    val packageName: String = "eu.kanade.tachiyomi",
    val debug: Boolean = false,
) : ConfigModule()
