import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    // Este plugin lee el google-services.json y lo inyecta.
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load local.properties for MAPS_API_KEY (non-checked-in)
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { input -> this@apply.load(input) }
}

android {
    namespace = "com.taxipro.usuariox"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.taxipro.usuariox"
        minSdk = flutter.minSdkVersion  // Facebook Auth requirement
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        // Provide Google Maps API key via manifest placeholder
        manifestPlaceholders["MAPS_API_KEY"] =
            (localProps.getProperty("MAPS_API_KEY") as String?)
                ?: (project.findProperty("MAPS_API_KEY") as String?)
                ?: System.getenv("MAPS_API_KEY")
                ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Dependencias de Flutter y Firebase son gestionadas por los plugins Flutter/FlutterFire

    // Google Maps y Play Services (Necesario para tu app y para Stripe)
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    implementation("com.google.android.gms:play-services-base:18.2.0")
    // Necesario para geolocator y localización:
    implementation("com.google.android.gms:play-services-location:21.0.1")
    // Material Components requerido por flutter_stripe PaymentSheet
    implementation("com.google.android.material:material:1.12.0")
}

// Bloque de configuración extra (lo que tenías al final de tu archivo)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Reduce noisy Java warnings from transitive plugins (harmless but clutter console)
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:-options")
}
