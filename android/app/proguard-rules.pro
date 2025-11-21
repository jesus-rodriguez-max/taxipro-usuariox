# Flutter specific rules for R8 / Proguard
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.android.**  { *; }
-keep class androidx.lifecycle.** { *; }

# Stripe SDK rules
-keep class com.stripe.android.** { *; }
-keep interface com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Rules from missing_rules.txt
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Google Play Core rules
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Google Sign-In rules
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.auth.** { *; }
-dontwarn com.google.firebase.auth.**
