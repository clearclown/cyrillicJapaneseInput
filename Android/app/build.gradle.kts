plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.github.triplet.play")
}

android {
    namespace = "com.pismo.keyboard"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.pismo.keyboard"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            storeFile = file("keystore/pismo-release.jks")
            storePassword = "pismo123"
            keyAlias = "pismo"
            keyPassword = "pismo123"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            isMinifyEnabled = false
            applicationIdSuffix = ".debug"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        viewBinding = true
    }

    androidResources {
        // Prevent Android from decompressing .gz files during build
        // This keeps the dictionary files compressed in the APK
        noCompress += listOf("gz")
    }

    sourceSets {
        getByName("main") {
            kotlin.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            kotlin.srcDirs("src/test/kotlin")
        }
        getByName("androidTest") {
            kotlin.srcDirs("src/androidTest/kotlin")
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    // JSON parsing for profiles
    implementation("com.google.code.gson:gson:2.10.1")

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}

// Google Play Publisher configuration
play {
    // Service account credentials JSON file path
    serviceAccountCredentials.set(file("play-service-account.json"))

    // Track to publish to: internal, alpha, beta, production
    track.set("internal")

    // Release status: completed, draft, halted, inProgress
    releaseStatus.set(com.github.triplet.gradle.androidpublisher.ReleaseStatus.DRAFT)

    // Default language for store listing
    defaultToAppBundles.set(true)
}
