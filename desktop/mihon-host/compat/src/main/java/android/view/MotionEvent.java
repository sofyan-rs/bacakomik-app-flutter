package android.view;

// SCANCORE: rebuilt from AOSP's android.jar stub (Apache-2.0) so the parts
// extensions use on computers work; the rest still throws "Stub!".

public final class MotionEvent extends android.view.InputEvent implements android.os.Parcelable {
    private long downTime;
    private long eventTime;
    private int action;
    private int source;
    private int deviceId;
    private PointerProperties[] properties = new PointerProperties[0];
    private PointerCoords[] coords = new PointerCoords[0];

    private MotionEvent() {}

    public static final int ACTION_BUTTON_PRESS = 11;
    public static final int ACTION_BUTTON_RELEASE = 12;
    public static final int ACTION_CANCEL = 3;
    public static final int ACTION_DOWN = 0;
    public static final int ACTION_HOVER_ENTER = 9;
    public static final int ACTION_HOVER_EXIT = 10;
    public static final int ACTION_HOVER_MOVE = 7;
    public static final int ACTION_MASK = 255;
    public static final int ACTION_MOVE = 2;
    public static final int ACTION_OUTSIDE = 4;
    public static final int ACTION_POINTER_1_DOWN = 5;
    public static final int ACTION_POINTER_1_UP = 6;
    public static final int ACTION_POINTER_2_DOWN = 261;
    public static final int ACTION_POINTER_2_UP = 262;
    public static final int ACTION_POINTER_3_DOWN = 517;
    public static final int ACTION_POINTER_3_UP = 518;
    public static final int ACTION_POINTER_DOWN = 5;
    public static final int ACTION_POINTER_ID_MASK = 65280;
    public static final int ACTION_POINTER_ID_SHIFT = 8;
    public static final int ACTION_POINTER_INDEX_MASK = 65280;
    public static final int ACTION_POINTER_INDEX_SHIFT = 8;
    public static final int ACTION_POINTER_UP = 6;
    public static final int ACTION_SCROLL = 8;
    public static final int ACTION_UP = 1;
    public static final int AXIS_BRAKE = 23;
    public static final int AXIS_DISTANCE = 24;
    public static final int AXIS_GAS = 22;
    public static final int AXIS_GENERIC_1 = 32;
    public static final int AXIS_GENERIC_10 = 41;
    public static final int AXIS_GENERIC_11 = 42;
    public static final int AXIS_GENERIC_12 = 43;
    public static final int AXIS_GENERIC_13 = 44;
    public static final int AXIS_GENERIC_14 = 45;
    public static final int AXIS_GENERIC_15 = 46;
    public static final int AXIS_GENERIC_16 = 47;
    public static final int AXIS_GENERIC_2 = 33;
    public static final int AXIS_GENERIC_3 = 34;
    public static final int AXIS_GENERIC_4 = 35;
    public static final int AXIS_GENERIC_5 = 36;
    public static final int AXIS_GENERIC_6 = 37;
    public static final int AXIS_GENERIC_7 = 38;
    public static final int AXIS_GENERIC_8 = 39;
    public static final int AXIS_GENERIC_9 = 40;
    public static final int AXIS_HAT_X = 15;
    public static final int AXIS_HAT_Y = 16;
    public static final int AXIS_HSCROLL = 10;
    public static final int AXIS_LTRIGGER = 17;
    public static final int AXIS_ORIENTATION = 8;
    public static final int AXIS_PRESSURE = 2;
    public static final int AXIS_RELATIVE_X = 27;
    public static final int AXIS_RELATIVE_Y = 28;
    public static final int AXIS_RTRIGGER = 18;
    public static final int AXIS_RUDDER = 20;
    public static final int AXIS_RX = 12;
    public static final int AXIS_RY = 13;
    public static final int AXIS_RZ = 14;
    public static final int AXIS_SCROLL = 26;
    public static final int AXIS_SIZE = 3;
    public static final int AXIS_THROTTLE = 19;
    public static final int AXIS_TILT = 25;
    public static final int AXIS_TOOL_MAJOR = 6;
    public static final int AXIS_TOOL_MINOR = 7;
    public static final int AXIS_TOUCH_MAJOR = 4;
    public static final int AXIS_TOUCH_MINOR = 5;
    public static final int AXIS_VSCROLL = 9;
    public static final int AXIS_WHEEL = 21;
    public static final int AXIS_X = 0;
    public static final int AXIS_Y = 1;
    public static final int AXIS_Z = 11;
    public static final int BUTTON_BACK = 8;
    public static final int BUTTON_FORWARD = 16;
    public static final int BUTTON_PRIMARY = 1;
    public static final int BUTTON_SECONDARY = 2;
    public static final int BUTTON_STYLUS_PRIMARY = 32;
    public static final int BUTTON_STYLUS_SECONDARY = 64;
    public static final int BUTTON_TERTIARY = 4;
    public static final int CLASSIFICATION_AMBIGUOUS_GESTURE = 1;
    public static final int CLASSIFICATION_DEEP_PRESS = 2;
    public static final int CLASSIFICATION_NONE = 0;
    public static final android.os.Parcelable.Creator<android.view.MotionEvent> CREATOR = null;
    public static final int EDGE_BOTTOM = 2;
    public static final int EDGE_LEFT = 4;
    public static final int EDGE_RIGHT = 8;
    public static final int EDGE_TOP = 1;
    public static final int FLAG_WINDOW_IS_OBSCURED = 1;
    public static final int FLAG_WINDOW_IS_PARTIALLY_OBSCURED = 2;
    public static final int INVALID_POINTER_ID = -1;
    public static final int TOOL_TYPE_ERASER = 4;
    public static final int TOOL_TYPE_FINGER = 1;
    public static final int TOOL_TYPE_MOUSE = 3;
    public static final int TOOL_TYPE_STYLUS = 2;
    public static final int TOOL_TYPE_UNKNOWN = 0;
    public static android.view.MotionEvent obtain(long p0, long p1, int p2, int p3, android.view.MotionEvent.PointerProperties[] p4, android.view.MotionEvent.PointerCoords[] p5, int p6, int p7, float p8, float p9, int p10, int p11, int p12, int p13) {
        MotionEvent e = new MotionEvent();
        e.downTime = p0;
        e.eventTime = p1;
        e.action = p2;
        e.properties = new PointerProperties[p3];
        e.coords = new PointerCoords[p3];
        for (int i = 0; i < p3; i++) {
            e.properties[i] = new PointerProperties(p4[i]);
            e.coords[i] = new PointerCoords(p5[i]);
        }
        e.deviceId = p10;
        e.source = p12;
        return e;
    }
    public static android.view.MotionEvent obtain(long p0, long p1, int p2, int p3, int[] p4, android.view.MotionEvent.PointerCoords[] p5, int p6, float p7, float p8, int p9, int p10, int p11, int p12) {
        throw new RuntimeException("Stub!");
    }
    public static android.view.MotionEvent obtain(long p0, long p1, int p2, float p3, float p4, float p5, float p6, int p7, float p8, float p9, int p10, int p11) {
        throw new RuntimeException("Stub!");
    }
    public static android.view.MotionEvent obtain(long p0, long p1, int p2, int p3, float p4, float p5, float p6, float p7, int p8, float p9, float p10, int p11, int p12) {
        throw new RuntimeException("Stub!");
    }
    public static android.view.MotionEvent obtain(long p0, long p1, int p2, float p3, float p4, int p5) {
        PointerProperties p = new PointerProperties();
        p.toolType = TOOL_TYPE_FINGER;
        PointerCoords c = new PointerCoords();
        c.x = p3;
        c.y = p4;
        c.pressure = 1f;
        c.size = 1f;
        return obtain(p0, p1, p2, 1, new PointerProperties[] {p}, new PointerCoords[] {c}, p5, 0, 1f, 1f, 0, 0, 0x00001002, 0);
    }
    public static android.view.MotionEvent obtain(android.view.MotionEvent p0) {
        return obtain(p0.downTime, p0.eventTime, p0.action, p0.coords.length, p0.properties, p0.coords, 0, 0, 1f, 1f, p0.deviceId, 0, p0.source, 0);
    }
    public static android.view.MotionEvent obtainNoHistory(android.view.MotionEvent p0) {
        throw new RuntimeException("Stub!");
    }
    public void recycle() {
        coords = new PointerCoords[0];
        properties = new PointerProperties[0];
    }
    public int getDeviceId() {
        return deviceId;
    }
    public int getSource() {
        return source;
    }
    public void setSource(int p0) {
        throw new RuntimeException("Stub!");
    }
    public int getAction() {
        return action;
    }
    public int getActionMasked() {
        return action & ACTION_MASK;
    }
    public int getActionIndex() {
        return (action & ACTION_POINTER_INDEX_MASK) >> ACTION_POINTER_INDEX_SHIFT;
    }
    public int getFlags() {
        throw new RuntimeException("Stub!");
    }
    public long getDownTime() {
        return downTime;
    }
    public long getEventTime() {
        return eventTime;
    }
    public float getX() {
        return coords.length > 0 ? coords[0].x : 0f;
    }
    public float getY() {
        return coords.length > 0 ? coords[0].y : 0f;
    }
    public float getPressure() {
        return coords.length > 0 ? coords[0].pressure : 0f;
    }
    public float getSize() {
        throw new RuntimeException("Stub!");
    }
    public float getTouchMajor() {
        return coords.length > 0 ? coords[0].touchMajor : 0f;
    }
    public float getTouchMinor() {
        throw new RuntimeException("Stub!");
    }
    public float getToolMajor() {
        throw new RuntimeException("Stub!");
    }
    public float getToolMinor() {
        throw new RuntimeException("Stub!");
    }
    public float getOrientation() {
        throw new RuntimeException("Stub!");
    }
    public float getAxisValue(int p0) {
        throw new RuntimeException("Stub!");
    }
    public int getPointerCount() {
        return coords.length;
    }
    public int getPointerId(int p0) {
        return properties[p0].id;
    }
    public int getToolType(int p0) {
        return properties[p0].toolType;
    }
    public int findPointerIndex(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getX(int p0) {
        return coords[p0].x;
    }
    public float getY(int p0) {
        return coords[p0].y;
    }
    public float getPressure(int p0) {
        return coords[p0].pressure;
    }
    public float getSize(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getTouchMajor(int p0) {
        return coords[p0].touchMajor;
    }
    public float getTouchMinor(int p0) {
        return coords[p0].touchMinor;
    }
    public float getToolMajor(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getToolMinor(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getOrientation(int p0) {
        return coords[p0].orientation;
    }
    public float getAxisValue(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public void getPointerCoords(int p0, android.view.MotionEvent.PointerCoords p1) {
        p1.copyFrom(coords[p0]);
    }
    public void getPointerProperties(int p0, android.view.MotionEvent.PointerProperties p1) {
        p1.copyFrom(properties[p0]);
    }
    public int getMetaState() {
        throw new RuntimeException("Stub!");
    }
    public int getButtonState() {
        throw new RuntimeException("Stub!");
    }
    public int getClassification() {
        throw new RuntimeException("Stub!");
    }
    public int getActionButton() {
        throw new RuntimeException("Stub!");
    }
    public float getRawX() {
        throw new RuntimeException("Stub!");
    }
    public float getRawY() {
        throw new RuntimeException("Stub!");
    }
    public float getRawX(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getRawY(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getXPrecision() {
        throw new RuntimeException("Stub!");
    }
    public float getYPrecision() {
        throw new RuntimeException("Stub!");
    }
    public int getHistorySize() {
        throw new RuntimeException("Stub!");
    }
    public long getHistoricalEventTime(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalX(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalY(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalPressure(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalSize(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalTouchMajor(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalTouchMinor(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalToolMajor(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalToolMinor(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalOrientation(int p0) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalAxisValue(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalX(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalY(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalPressure(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalSize(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalTouchMajor(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalTouchMinor(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalToolMajor(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalToolMinor(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalOrientation(int p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public float getHistoricalAxisValue(int p0, int p1, int p2) {
        throw new RuntimeException("Stub!");
    }
    public void getHistoricalPointerCoords(int p0, int p1, android.view.MotionEvent.PointerCoords p2) {
        throw new RuntimeException("Stub!");
    }
    public int getEdgeFlags() {
        throw new RuntimeException("Stub!");
    }
    public void setEdgeFlags(int p0) {
        throw new RuntimeException("Stub!");
    }
    public void setAction(int p0) {
        throw new RuntimeException("Stub!");
    }
    public void offsetLocation(float p0, float p1) {
        throw new RuntimeException("Stub!");
    }
    public void setLocation(float p0, float p1) {
        throw new RuntimeException("Stub!");
    }
    public void transform(android.graphics.Matrix p0) {
        throw new RuntimeException("Stub!");
    }
    public void addBatch(long p0, float p1, float p2, float p3, float p4, int p5) {
        throw new RuntimeException("Stub!");
    }
    public void addBatch(long p0, android.view.MotionEvent.PointerCoords[] p1, int p2) {
        throw new RuntimeException("Stub!");
    }
    public java.lang.String toString() {
        throw new RuntimeException("Stub!");
    }
    public static java.lang.String actionToString(int p0) {
        throw new RuntimeException("Stub!");
    }
    public static java.lang.String axisToString(int p0) {
        throw new RuntimeException("Stub!");
    }
    public static int axisFromString(java.lang.String p0) {
        throw new RuntimeException("Stub!");
    }
    public boolean isButtonPressed(int p0) {
        throw new RuntimeException("Stub!");
    }
    public void writeToParcel(android.os.Parcel p0, int p1) {
        throw new RuntimeException("Stub!");
    }
    public final static class PointerCoords {
        public float orientation;
        public float pressure;
        public float size;
        public float toolMajor;
        public float toolMinor;
        public float touchMajor;
        public float touchMinor;
        public float x;
        public float y;
        public PointerCoords() {

        }
        public PointerCoords(android.view.MotionEvent.PointerCoords p0) {
            copyFrom(p0);
        }
        public void clear() {
            orientation = pressure = size = toolMajor = toolMinor = touchMajor = touchMinor = x = y = 0f;
        }
        public void copyFrom(android.view.MotionEvent.PointerCoords p0) {
            orientation = p0.orientation;
            pressure = p0.pressure;
            size = p0.size;
            toolMajor = p0.toolMajor;
            toolMinor = p0.toolMinor;
            touchMajor = p0.touchMajor;
            touchMinor = p0.touchMinor;
            x = p0.x;
            y = p0.y;
        }
        public float getAxisValue(int p0) {
            throw new RuntimeException("Stub!");
        }
        public void setAxisValue(int p0, float p1) {
            throw new RuntimeException("Stub!");
        }
    }
    public final static class PointerProperties {
        public int id;
        public int toolType;
        public PointerProperties() {

        }
        public PointerProperties(android.view.MotionEvent.PointerProperties p0) {
            copyFrom(p0);
        }
        public void clear() {
            throw new RuntimeException("Stub!");
        }
        public void copyFrom(android.view.MotionEvent.PointerProperties p0) {
            id = p0.id;
            toolType = p0.toolType;
        }
        public boolean equals(java.lang.Object p0) {
            throw new RuntimeException("Stub!");
        }
        public int hashCode() {
            throw new RuntimeException("Stub!");
        }
    }
}
