package android.content.res;

// YORU: rebuilt from AOSP's android.jar stub (Apache-2.0) so extensions can
// read the configuration (Keiyoushi's web view helper asks for night mode
// before it opens a page). A light, portrait screen in the default locale;
// what extensions do not use still throws "Stub!".

import android.os.Parcel;
import android.os.Parcelable;
import java.util.Locale;

public final class Configuration implements Parcelable, Comparable<Configuration> {
    public static final int COLOR_MODE_HDR_MASK = 12;
    public static final int COLOR_MODE_HDR_NO = 4;
    public static final int COLOR_MODE_HDR_SHIFT = 2;
    public static final int COLOR_MODE_HDR_UNDEFINED = 0;
    public static final int COLOR_MODE_HDR_YES = 8;
    public static final int COLOR_MODE_UNDEFINED = 0;
    public static final int COLOR_MODE_WIDE_COLOR_GAMUT_MASK = 3;
    public static final int COLOR_MODE_WIDE_COLOR_GAMUT_NO = 1;
    public static final int COLOR_MODE_WIDE_COLOR_GAMUT_UNDEFINED = 0;
    public static final int COLOR_MODE_WIDE_COLOR_GAMUT_YES = 2;
    public static final int DENSITY_DPI_UNDEFINED = 0;
    public static final int HARDKEYBOARDHIDDEN_NO = 1;
    public static final int HARDKEYBOARDHIDDEN_UNDEFINED = 0;
    public static final int HARDKEYBOARDHIDDEN_YES = 2;
    public static final int KEYBOARDHIDDEN_NO = 1;
    public static final int KEYBOARDHIDDEN_UNDEFINED = 0;
    public static final int KEYBOARDHIDDEN_YES = 2;
    public static final int KEYBOARD_12KEY = 3;
    public static final int KEYBOARD_NOKEYS = 1;
    public static final int KEYBOARD_QWERTY = 2;
    public static final int KEYBOARD_UNDEFINED = 0;
    public static final int MNC_ZERO = 65535;
    public static final int NAVIGATIONHIDDEN_NO = 1;
    public static final int NAVIGATIONHIDDEN_UNDEFINED = 0;
    public static final int NAVIGATIONHIDDEN_YES = 2;
    public static final int NAVIGATION_DPAD = 2;
    public static final int NAVIGATION_NONAV = 1;
    public static final int NAVIGATION_TRACKBALL = 3;
    public static final int NAVIGATION_UNDEFINED = 0;
    public static final int NAVIGATION_WHEEL = 4;
    public static final int ORIENTATION_LANDSCAPE = 2;
    public static final int ORIENTATION_PORTRAIT = 1;
    public static final int ORIENTATION_SQUARE = 3;
    public static final int ORIENTATION_UNDEFINED = 0;
    public static final int SCREENLAYOUT_LAYOUTDIR_LTR = 64;
    public static final int SCREENLAYOUT_LAYOUTDIR_MASK = 192;
    public static final int SCREENLAYOUT_LAYOUTDIR_RTL = 128;
    public static final int SCREENLAYOUT_LAYOUTDIR_SHIFT = 6;
    public static final int SCREENLAYOUT_LAYOUTDIR_UNDEFINED = 0;
    public static final int SCREENLAYOUT_LONG_MASK = 48;
    public static final int SCREENLAYOUT_LONG_NO = 16;
    public static final int SCREENLAYOUT_LONG_UNDEFINED = 0;
    public static final int SCREENLAYOUT_LONG_YES = 32;
    public static final int SCREENLAYOUT_ROUND_MASK = 768;
    public static final int SCREENLAYOUT_ROUND_NO = 256;
    public static final int SCREENLAYOUT_ROUND_UNDEFINED = 0;
    public static final int SCREENLAYOUT_ROUND_YES = 512;
    public static final int SCREENLAYOUT_SIZE_LARGE = 3;
    public static final int SCREENLAYOUT_SIZE_MASK = 15;
    public static final int SCREENLAYOUT_SIZE_NORMAL = 2;
    public static final int SCREENLAYOUT_SIZE_SMALL = 1;
    public static final int SCREENLAYOUT_SIZE_UNDEFINED = 0;
    public static final int SCREENLAYOUT_SIZE_XLARGE = 4;
    public static final int SCREENLAYOUT_UNDEFINED = 0;
    public static final int SCREEN_HEIGHT_DP_UNDEFINED = 0;
    public static final int SCREEN_WIDTH_DP_UNDEFINED = 0;
    public static final int SMALLEST_SCREEN_WIDTH_DP_UNDEFINED = 0;
    public static final int TOUCHSCREEN_FINGER = 3;
    public static final int TOUCHSCREEN_NOTOUCH = 1;
    public static final int TOUCHSCREEN_STYLUS = 2;
    public static final int TOUCHSCREEN_UNDEFINED = 0;
    public static final int UI_MODE_NIGHT_MASK = 48;
    public static final int UI_MODE_NIGHT_NO = 16;
    public static final int UI_MODE_NIGHT_UNDEFINED = 0;
    public static final int UI_MODE_NIGHT_YES = 32;
    public static final int UI_MODE_TYPE_APPLIANCE = 5;
    public static final int UI_MODE_TYPE_CAR = 3;
    public static final int UI_MODE_TYPE_DESK = 2;
    public static final int UI_MODE_TYPE_MASK = 15;
    public static final int UI_MODE_TYPE_NORMAL = 1;
    public static final int UI_MODE_TYPE_TELEVISION = 4;
    public static final int UI_MODE_TYPE_UNDEFINED = 0;
    public static final int UI_MODE_TYPE_VR_HEADSET = 7;
    public static final int UI_MODE_TYPE_WATCH = 6;

    public static final Parcelable.Creator<Configuration> CREATOR = null;

    public int colorMode;
    public int densityDpi;
    public float fontScale;
    public int hardKeyboardHidden;
    public int keyboard;
    public int keyboardHidden;
    public Locale locale;
    public int mcc;
    public int mnc;
    public int navigation;
    public int navigationHidden;
    public int orientation;
    public int screenHeightDp;
    public int screenLayout;
    public int screenWidthDp;
    public int smallestScreenWidthDp;
    public int touchscreen;
    public int uiMode;

    public Configuration() {
        setToDefaults();
    }

    public Configuration(Configuration o) {
        setTo(o);
    }

    // The screen extensions see: Resources.getSystem()'s DisplayMetrics
    // (1280 x 2856 at density 1, the size of the off-screen web view).
    static Configuration defaults() {
        Configuration c = new Configuration();
        c.fontScale = 1f;
        c.densityDpi = 160;
        c.orientation = ORIENTATION_PORTRAIT;
        c.screenWidthDp = 1280;
        c.screenHeightDp = 2856;
        c.smallestScreenWidthDp = 1280;
        c.screenLayout = SCREENLAYOUT_SIZE_XLARGE | SCREENLAYOUT_LONG_YES | SCREENLAYOUT_LAYOUTDIR_LTR | SCREENLAYOUT_ROUND_NO;
        c.touchscreen = TOUCHSCREEN_FINGER;
        c.keyboard = KEYBOARD_NOKEYS;
        c.keyboardHidden = KEYBOARDHIDDEN_YES;
        c.hardKeyboardHidden = HARDKEYBOARDHIDDEN_YES;
        c.navigation = NAVIGATION_NONAV;
        c.navigationHidden = NAVIGATIONHIDDEN_YES;
        c.uiMode = UI_MODE_TYPE_NORMAL | UI_MODE_NIGHT_NO;
        c.colorMode = COLOR_MODE_WIDE_COLOR_GAMUT_NO | COLOR_MODE_HDR_NO;
        return c;
    }

    public boolean isLayoutSizeAtLeast(int size) {
        int cur = screenLayout & SCREENLAYOUT_SIZE_MASK;
        return cur != SCREENLAYOUT_SIZE_UNDEFINED && cur >= size;
    }

    public void setTo(Configuration o) {
        colorMode = o.colorMode;
        densityDpi = o.densityDpi;
        fontScale = o.fontScale;
        hardKeyboardHidden = o.hardKeyboardHidden;
        keyboard = o.keyboard;
        keyboardHidden = o.keyboardHidden;
        locale = o.locale;
        mcc = o.mcc;
        mnc = o.mnc;
        navigation = o.navigation;
        navigationHidden = o.navigationHidden;
        orientation = o.orientation;
        screenHeightDp = o.screenHeightDp;
        screenLayout = o.screenLayout;
        screenWidthDp = o.screenWidthDp;
        smallestScreenWidthDp = o.smallestScreenWidthDp;
        touchscreen = o.touchscreen;
        uiMode = o.uiMode;
    }

    @Override
    public String toString() {
        return "{" + fontScale + " " + mcc + "mcc" + mnc + "mnc " + locale + " sw" + smallestScreenWidthDp + "dp w"
                + screenWidthDp + "dp h" + screenHeightDp + "dp " + densityDpi + "dpi uiMode=" + uiMode + "}";
    }

    public void setToDefaults() {
        fontScale = 1f;
        mcc = mnc = 0;
        locale = Locale.getDefault();
        screenLayout = SCREENLAYOUT_UNDEFINED;
        colorMode = COLOR_MODE_UNDEFINED;
        touchscreen = TOUCHSCREEN_UNDEFINED;
        keyboard = KEYBOARD_UNDEFINED;
        keyboardHidden = KEYBOARDHIDDEN_UNDEFINED;
        hardKeyboardHidden = HARDKEYBOARDHIDDEN_UNDEFINED;
        navigation = NAVIGATION_UNDEFINED;
        navigationHidden = NAVIGATIONHIDDEN_UNDEFINED;
        orientation = ORIENTATION_UNDEFINED;
        uiMode = UI_MODE_TYPE_UNDEFINED;
        screenWidthDp = SCREEN_WIDTH_DP_UNDEFINED;
        screenHeightDp = SCREEN_HEIGHT_DP_UNDEFINED;
        smallestScreenWidthDp = SMALLEST_SCREEN_WIDTH_DP_UNDEFINED;
        densityDpi = DENSITY_DPI_UNDEFINED;
    }

    public int updateFrom(Configuration delta) {
        throw new RuntimeException("Stub!");
    }

    public int diff(Configuration delta) {
        throw new RuntimeException("Stub!");
    }

    public static boolean needNewResources(int configChanges, int interestingChanges) {
        return (configChanges & interestingChanges) != 0;
    }

    public int describeContents() {
        return 0;
    }

    public void writeToParcel(Parcel dest, int flags) {
        throw new RuntimeException("Stub!");
    }

    public void readFromParcel(Parcel source) {
        throw new RuntimeException("Stub!");
    }

    public boolean isNightModeActive() {
        return (uiMode & UI_MODE_NIGHT_MASK) == UI_MODE_NIGHT_YES;
    }

    public int compareTo(Configuration that) {
        return toString().compareTo(that.toString());
    }

    public boolean equals(Configuration that) {
        return that != null && toString().equals(that.toString());
    }

    @Override
    public boolean equals(Object that) {
        return that instanceof Configuration && equals((Configuration) that);
    }

    @Override
    public int hashCode() {
        return toString().hashCode();
    }

    public android.os.LocaleList getLocales() {
        throw new RuntimeException("Stub!");
    }

    public void setLocales(android.os.LocaleList locales) {
        throw new RuntimeException("Stub!");
    }

    public void setLocale(Locale loc) {
        locale = loc;
    }

    public int getLayoutDirection() {
        return (screenLayout & SCREENLAYOUT_LAYOUTDIR_MASK) == SCREENLAYOUT_LAYOUTDIR_RTL ? 1 : 0;
    }

    public void setLayoutDirection(Locale loc) {
        throw new RuntimeException("Stub!");
    }

    public boolean isScreenRound() {
        return (screenLayout & SCREENLAYOUT_ROUND_MASK) == SCREENLAYOUT_ROUND_YES;
    }

    public boolean isScreenWideColorGamut() {
        return (colorMode & COLOR_MODE_WIDE_COLOR_GAMUT_MASK) == COLOR_MODE_WIDE_COLOR_GAMUT_YES;
    }

    public boolean isScreenHdr() {
        return (colorMode & COLOR_MODE_HDR_MASK) == COLOR_MODE_HDR_YES;
    }
}
