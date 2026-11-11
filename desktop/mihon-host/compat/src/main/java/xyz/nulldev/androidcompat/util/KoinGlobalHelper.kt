/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: Koin replaced by a plain registry of the singletons
// AndroidCompatModule describes; the name stays for the Java callers.
package xyz.nulldev.androidcompat.util

import java.util.concurrent.ConcurrentHashMap

object KoinGlobalHelper {
    private val factories = ConcurrentHashMap<Class<*>, () -> Any>()
    private val instances = ConcurrentHashMap<Class<*>, Any>()

    fun <T : Any> register(
        type: Class<T>,
        factory: () -> T,
    ) {
        factories[type] = factory
    }

    @JvmStatic
    fun <T : Any> instance(type: Class<T>): T {
        instances[type]?.let { return type.cast(it) }
        synchronized(this) {
            instances[type]?.let { return type.cast(it) }
            val factory = factories[type] ?: error("AndroidCompat: nothing provides ${type.name}")
            val created = factory()
            instances[type] = created
            return type.cast(created)
        }
    }

    inline fun <reified T : Any> get(): T = instance(T::class.java)
}
