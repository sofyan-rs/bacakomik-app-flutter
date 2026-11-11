package android.util;

// SCANCORE: rebuilt from AOSP's android.jar stub (Apache-2.0) so the parts
// extensions use on computers work; the rest still throws "Stub!".

public class DisplayMetrics {
    public static final int DENSITY_140 = 140;
    public static final int DENSITY_180 = 180;
    public static final int DENSITY_200 = 200;
    public static final int DENSITY_220 = 220;
    public static final int DENSITY_260 = 260;
    public static final int DENSITY_280 = 280;
    public static final int DENSITY_300 = 300;
    public static final int DENSITY_340 = 340;
    public static final int DENSITY_360 = 360;
    public static final int DENSITY_400 = 400;
    public static final int DENSITY_420 = 420;
    public static final int DENSITY_440 = 440;
    public static final int DENSITY_450 = 450;
    public static final int DENSITY_560 = 560;
    public static final int DENSITY_600 = 600;
    public static final int DENSITY_DEFAULT = 160;
    public static final int DENSITY_DEVICE_STABLE = 160;
    public static final int DENSITY_HIGH = 240;
    public static final int DENSITY_LOW = 120;
    public static final int DENSITY_MEDIUM = 160;
    public static final int DENSITY_TV = 213;
    public static final int DENSITY_XHIGH = 320;
    public static final int DENSITY_XXHIGH = 480;
    public static final int DENSITY_XXXHIGH = 640;
    public float density;
    public int densityDpi;
    public int heightPixels;
    public float scaledDensity;
    public int widthPixels;
    public float xdpi;
    public float ydpi;
    public DisplayMetrics() {
        setToDefaults();
    }
    public void setTo(android.util.DisplayMetrics p0) {
        density = p0.density;
        densityDpi = p0.densityDpi;
        scaledDensity = p0.scaledDensity;
        widthPixels = p0.widthPixels;
        heightPixels = p0.heightPixels;
        xdpi = p0.xdpi;
        ydpi = p0.ydpi;
    }
    public void setToDefaults() {
        density = 1f;
        densityDpi = DENSITY_DEFAULT;
        scaledDensity = 1f;
        widthPixels = 1280;
        heightPixels = 2856;
        xdpi = DENSITY_DEFAULT;
        ydpi = DENSITY_DEFAULT;
    }
    public boolean equals(java.lang.Object p0) {
        throw new RuntimeException("Stub!");
    }
    public boolean equals(android.util.DisplayMetrics p0) {
        throw new RuntimeException("Stub!");
    }
    public int hashCode() {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String toString() {
        throw new RuntimeException("Stub!");
    }
}
