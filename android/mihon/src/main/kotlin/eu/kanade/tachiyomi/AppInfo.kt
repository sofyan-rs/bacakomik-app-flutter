// What extensions see of the app (SCANCORE fills it in at start-up). Called
// as AppInfo.INSTANCE.getVersionCode(), as in Mihon.
package eu.kanade.tachiyomi

@Suppress("UNUSED")
object AppInfo {
    @Volatile
    private var code: Int = 1

    @Volatile
    private var name: String = "SCANCORE"

    fun set(
        versionCode: Int,
        versionName: String,
    ) {
        code = versionCode
        name = versionName
    }

    fun getVersionCode(): Int = code

    fun getVersionName(): String = name
}
