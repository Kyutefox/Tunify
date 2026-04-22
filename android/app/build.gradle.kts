import org.gradle.api.tasks.Copy

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kyutefox.tunify"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.kyutefox.tunify"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Disable minification so network/reflection (YouTube API, just_audio) work in release.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// Ship the Rust server as a fake JNI .so so it lands in nativeLibraryDir, where exec is allowed.
// (SELinux blocks executing binaries extracted into app-writable dirs from Flutter assets.)
val bundledBackendSource =
    rootProject.layout.projectDirectory.file("../assets/bundled_backend/tunify_rust_backend")
tasks.register<Copy>("syncBundledBackend") {
    val src = bundledBackendSource.asFile
    onlyIf { src.exists() && src.length() > 0L }
    from(src)
    into(layout.projectDirectory.dir("src/main/jniLibs/arm64-v8a"))
    rename { _: String -> "libtunify_backend_exec.so" }
}
tasks.named("preBuild").configure { dependsOn(tasks.named("syncBundledBackend")) }

dependencies {
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}
