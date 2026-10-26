// The one Compose annotation Mihon's source models carry; the host has no
// Compose. (SCANCORE)
package androidx.compose.runtime

@MustBeDocumented
@Retention(AnnotationRetention.BINARY)
@Target(AnnotationTarget.CLASS, AnnotationTarget.FUNCTION, AnnotationTarget.PROPERTY_GETTER, AnnotationTarget.PROPERTY)
annotation class Stable
