/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: a small stand-in for Suwayomi's Typesafe-Config based manager.
// The host sets its values in code (see CompatSettings); modules are looked
// up by class as before.
package xyz.nulldev.ts.config

import java.util.concurrent.ConcurrentHashMap

abstract class ConfigModule

open class ConfigManager {
    private val modules = ConcurrentHashMap<Class<*>, ConfigModule>()

    fun registerModules(vararg list: ConfigModule) {
        list.forEach { modules[it.javaClass] = it }
    }

    fun <T : ConfigModule> module(type: Class<T>): T =
        type.cast(modules[type] ?: error("AndroidCompat: ${type.simpleName} is not registered"))

    inline fun <reified T : ConfigModule> module(): T = module(T::class.java)
}

object GlobalConfigManager : ConfigManager()

// Where the emulated Android app keeps its files; set by the host before
// anything starts (system property yoru.mihon.root). YORU: renamed from
// SCANCORE's scancore.host.root.
val ApplicationRootDir: String
    get() = System.getProperty("yoru.mihon.root") ?: (System.getProperty("user.home") + "/.yoru-mihon-host")
