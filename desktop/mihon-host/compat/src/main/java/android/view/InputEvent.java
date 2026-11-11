package android.view;

// SCANCORE: rebuilt from AOSP's android.jar stub (Apache-2.0) so the parts
// extensions use on computers work; the rest still throws "Stub!".

public abstract class InputEvent implements android.os.Parcelable {
    public static final android.os.Parcelable.Creator<android.view.InputEvent> CREATOR = null;
    public abstract int getDeviceId();
    public final android.view.InputDevice getDevice() {
        throw new RuntimeException("Stub!");
    }
    public abstract int getSource();
    public boolean isFromSource(int p0) {
        throw new RuntimeException("Stub!");
    }
    public abstract long getEventTime();
    public int describeContents() {
        throw new RuntimeException("Stub!");
    }
}
