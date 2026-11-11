/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: kotlin-logging's call style over plain SLF4J.
package xyz.nulldev.androidcompat.util

import org.slf4j.Logger
import org.slf4j.LoggerFactory

class CompatLogger(
    private val logger: Logger,
) {
    fun debug(message: () -> Any?) {
        if (logger.isDebugEnabled) logger.debug(message().toString())
    }

    fun warn(message: () -> Any?) {
        if (logger.isWarnEnabled) logger.warn(message().toString())
    }

    fun error(
        throwable: Throwable? = null,
        message: () -> Any?,
    ) {
        if (logger.isErrorEnabled) logger.error(message().toString(), throwable)
    }

    companion object {
        fun logger(owner: Class<*>) = CompatLogger(LoggerFactory.getLogger(owner))
    }
}
