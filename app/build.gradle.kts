import java.util.*


plugins {
    id("com.android.application")
    kotlin("android")
    id("com.google.devtools.ksp")
}

val properties = Properties()
val localPropertiesFile: File = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { properties.load(it) }
}

android {
    compileSdk = 36
    buildToolsVersion = "36.0.0"
    namespace = "dev.celenity.browser.tv"

    defaultConfig {
        applicationId = "dev.celenity.browser.tv"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.0.1"
        buildConfigField("Boolean", "BUILT_IN_AUTO_UPDATE", "true")

        javaCompileOptions {
            annotationProcessorOptions {
                arguments += mapOf(
                    "room.incremental" to "true",
                    //used when AppDatabase @Database annotation exportSchema = true. Useful for migrations
                    "room.schemaLocation" to "$projectDir/schemas"
                )
            }
        }
    }

    signingConfigs {
        create("release") {
            storeFile = properties.getProperty("storeFile", null)?.let { rootProject.file(it) }
            storePassword = properties.getProperty("storePassword", "")
            keyAlias = properties.getProperty("keyAlias", "")
            keyPassword = properties.getProperty("keyPassword", "")
        }
    }

    buildTypes {
        getByName("debug") {
            isDebuggable = true
        }
        getByName("release") {
            isDebuggable = false
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
            isUniversalApk = false
        }
    }

    applicationVariants.all {
        val variant = this
        variant.outputs
            .map { it as com.android.build.gradle.internal.api.BaseVariantOutputImpl }
            .forEach { output ->
                //val builtType = variant.buildType.name
                val versionName = variant.versionName
                val arch = output.filters.first().identifier
                output.outputFileName =
                    "browser-tv-${versionName}(${arch}).apk"
            }
    }

    buildFeatures {
        viewBinding = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
        }
    }
}

dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar"))))

    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("androidx.constraintlayout:constraintlayout:2.2.1")
    implementation("androidx.recyclerview:recyclerview:1.4.0")

    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.2.20")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")

    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.9.4")

    val roomVersion = "2.8.0"
    implementation("androidx.room:room-runtime:$roomVersion")
    annotationProcessor("androidx.room:room-compiler:$roomVersion")
    ksp("androidx.room:room-compiler:$roomVersion")
    implementation("androidx.room:room-ktx:$roomVersion")

    implementation("com.github.truefedex:segmented-button:v1.0.0")
    implementation("de.halfbit:pinned-section-listview:1.0.0")

    // https://maven.mozilla.org/?prefix=maven2/org/mozilla/geckoview/
    val geckoviewVersion = "143.0.20250923200700"
    implementation("org.mozilla.geckoview:geckoview-arm64-v8a:$geckoviewVersion")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.15.1")
}
