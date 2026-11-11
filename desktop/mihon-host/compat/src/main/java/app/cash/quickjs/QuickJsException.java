/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

package app.cash.quickjs;

public final class QuickJsException extends RuntimeException {
    public QuickJsException(String message) {
        super(message);
    }

    public QuickJsException(String message, Throwable cause) {
        super(message, cause);
    }
}
