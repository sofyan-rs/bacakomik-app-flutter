package org.kurodev.bacakomik

import android.app.Application
import org.kurodev.bacakomik.mihon.MihonHost
import org.kurodev.bacakomik.mihon.MihonProxy

class BacaKomikApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Background downloads of Mihon pages may run with no activity and
        // no Dart (WorkManager after the app was closed): the local server
        // they fetch from has to be up with the process.
        if (MihonHost.supported) runCatching { MihonProxy.start(this) }
    }
}
