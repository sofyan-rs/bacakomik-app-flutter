/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: system properties set in code instead of a config file.
package xyz.nulldev.androidcompat.config

import xyz.nulldev.ts.config.ConfigModule

class SystemConfigModule(
    val isDebuggable: Boolean = false,
    private val properties: Map<String, Any> = emptyMap(),
) : ConfigModule() {
    fun getStringProperty(property: String) = properties.getValue(property).toString()

    fun getIntProperty(property: String) = (properties.getValue(property) as Number).toInt()

    fun getLongProperty(property: String) = (properties.getValue(property) as Number).toLong()

    fun getBooleanProperty(property: String) = properties.getValue(property) as Boolean

    fun hasProperty(property: String) = properties.containsKey(property)
}
