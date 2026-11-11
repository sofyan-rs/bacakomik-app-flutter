package android.content.res;

// SCANCORE: rebuilt from AOSP's android.jar stub (Apache-2.0) so the parts
// extensions use on computers work; the rest still throws "Stub!".

public class Resources {
    private static final Resources SYSTEM = new Resources(null, new android.util.DisplayMetrics(), null);
    private final android.util.DisplayMetrics metrics;
    // YORU: a configuration to read (light, portrait; see Configuration).
    private final android.content.res.Configuration configuration;
    public static final int ID_NULL = 0;
    public Resources(android.content.res.AssetManager p0, android.util.DisplayMetrics p1, android.content.res.Configuration p2) {
        metrics = p1 != null ? p1 : new android.util.DisplayMetrics();
        configuration = p2 != null ? p2 : android.content.res.Configuration.defaults();
    }
    public static android.content.res.Resources getSystem() {
        return SYSTEM;
    }
    public java.lang.CharSequence getText(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public android.graphics.Typeface getFont(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.lang.CharSequence getQuantityText(int p0, int p1) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String getString(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String getString(int p0, java.lang.Object... p1) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String getQuantityString(int p0, int p1, java.lang.Object... p2) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String getQuantityString(int p0, int p1) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.lang.CharSequence getText(int p0, java.lang.CharSequence p1) {
        throw new RuntimeException("Stub!");
    }
    public java.lang.CharSequence[] getTextArray(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String[] getStringArray(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public int[] getIntArray(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public android.content.res.TypedArray obtainTypedArray(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public float getDimension(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public int getDimensionPixelOffset(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public int getDimensionPixelSize(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public float getFraction(int p0, int p1, int p2) {
        throw new RuntimeException("Stub!");
    }
    public android.graphics.drawable.Drawable getDrawable(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public android.graphics.drawable.Drawable getDrawable(int p0, android.content.res.Resources.Theme p1) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public android.graphics.drawable.Drawable getDrawableForDensity(int p0, int p1) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public android.graphics.drawable.Drawable getDrawableForDensity(int p0, int p1, android.content.res.Resources.Theme p2) {
        throw new RuntimeException("Stub!");
    }
    public android.graphics.Movie getMovie(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public int getColor(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public int getColor(int p0, android.content.res.Resources.Theme p1) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public android.content.res.ColorStateList getColorStateList(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public android.content.res.ColorStateList getColorStateList(int p0, android.content.res.Resources.Theme p1) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public boolean getBoolean(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public int getInteger(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public float getFloat(int p0) {
        throw new RuntimeException("Stub!");
    }
    public android.content.res.XmlResourceParser getLayout(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public android.content.res.XmlResourceParser getAnimation(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public android.content.res.XmlResourceParser getXml(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.io.InputStream openRawResource(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.io.InputStream openRawResource(int p0, android.util.TypedValue p1) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public android.content.res.AssetFileDescriptor openRawResourceFd(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public void getValue(int p0, android.util.TypedValue p1, boolean p2) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public void getValueForDensity(int p0, int p1, android.util.TypedValue p2, boolean p3) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public void getValue(java.lang.String p0, android.util.TypedValue p1, boolean p2) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public static int getAttributeSetSourceResId(android.util.AttributeSet p0) {
        throw new RuntimeException("Stub!");
    }
    public final android.content.res.Resources.Theme newTheme() {
        throw new RuntimeException("Stub!");
    }
    public android.content.res.TypedArray obtainAttributes(android.util.AttributeSet p0, int[] p1) {
        throw new RuntimeException("Stub!");
    }
    public void updateConfiguration(android.content.res.Configuration p0, android.util.DisplayMetrics p1) {
        throw new RuntimeException("Stub!");
    }
    public android.util.DisplayMetrics getDisplayMetrics() {
        return metrics;
    }
    public android.content.res.Configuration getConfiguration() {
        return configuration;
    }
    public int getIdentifier(java.lang.String p0, java.lang.String p1, java.lang.String p2) {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String getResourceName(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String getResourcePackageName(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String getResourceTypeName(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String getResourceEntryName(int p0) throws android.content.res.Resources.NotFoundException {
        throw new RuntimeException("Stub!");
    }
    public void parseBundleExtras(android.content.res.XmlResourceParser p0, android.os.Bundle p1) throws java.io.IOException, org.xmlpull.v1.XmlPullParserException {
        throw new RuntimeException("Stub!");
    }
    public void parseBundleExtra(java.lang.String p0, android.util.AttributeSet p1, android.os.Bundle p2) throws org.xmlpull.v1.XmlPullParserException {
        throw new RuntimeException("Stub!");
    }
    public final android.content.res.AssetManager getAssets() {
        throw new RuntimeException("Stub!");
    }
    public final void flushLayoutCache() {
        throw new RuntimeException("Stub!");
    }
    public final void finishPreloading() {
        throw new RuntimeException("Stub!");
    }
    public void addLoaders(android.content.res.loader.ResourcesLoader... p0) {
        throw new RuntimeException("Stub!");
    }
    public void removeLoaders(android.content.res.loader.ResourcesLoader... p0) {
        throw new RuntimeException("Stub!");
    }
    public static class NotFoundException extends java.lang.RuntimeException {
        public NotFoundException() {
            throw new RuntimeException("Stub!");
        }
        public NotFoundException(java.lang.String p0) {
            throw new RuntimeException("Stub!");
        }
        public NotFoundException(java.lang.String p0, java.lang.Exception p1) {
            throw new RuntimeException("Stub!");
        }
    }
    public final static class Theme {
        public void applyStyle(int p0, boolean p1) {
            throw new RuntimeException("Stub!");
        }
        public void setTo(android.content.res.Resources.Theme p0) {
            throw new RuntimeException("Stub!");
        }
        public android.content.res.TypedArray obtainStyledAttributes(int[] p0) {
            throw new RuntimeException("Stub!");
        }
        public android.content.res.TypedArray obtainStyledAttributes(int p0, int[] p1) throws android.content.res.Resources.NotFoundException {
            throw new RuntimeException("Stub!");
        }
        public android.content.res.TypedArray obtainStyledAttributes(android.util.AttributeSet p0, int[] p1, int p2, int p3) {
            throw new RuntimeException("Stub!");
        }
        public boolean resolveAttribute(int p0, android.util.TypedValue p1, boolean p2) {
            throw new RuntimeException("Stub!");
        }
        public android.content.res.Resources getResources() {
            throw new RuntimeException("Stub!");
        }
        public android.graphics.drawable.Drawable getDrawable(int p0) throws android.content.res.Resources.NotFoundException {
            throw new RuntimeException("Stub!");
        }
        public int getChangingConfigurations() {
            throw new RuntimeException("Stub!");
        }
        public void dump(int p0, java.lang.String p1, java.lang.String p2) {
            throw new RuntimeException("Stub!");
        }
        public void rebase() {
            throw new RuntimeException("Stub!");
        }
        public int getExplicitStyle(android.util.AttributeSet p0) {
            throw new RuntimeException("Stub!");
        }
        public int[] getAttributeResolutionStack(int p0, int p1, int p2) {
            throw new RuntimeException("Stub!");
        }
    }
}
