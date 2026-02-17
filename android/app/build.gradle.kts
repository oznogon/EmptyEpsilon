plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "eu.daid.emptyepsilon"
    compileSdk = 34
    ndkVersion = "26.3.11579264"

    defaultConfig {
        applicationId = "eu.daid.emptyepsilon"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "2024.02.16"

        ndk {
            // Only build for 64-bit ABIs (modern Android standard)
            // 32-bit ABIs have pointer size issues in SeriousProton
            abiFilters += listOf("arm64-v8a", "x86_64")
        }

        externalNativeBuild {
            cmake {
                arguments += listOf(
                    "-DANDROID_STL=c++_shared",
                    "-DANDROID_PLATFORM=android-26",
                    "-DSERIOUS_PROTON_DIR=\${projectDir}/src/main/cpp/SeriousProton",
                    "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
                )
                cppFlags += listOf("-std=c++17", "-DGLM_FORCE_CXX17=1")
                targets += "EmptyEpsilon"
            }
        }
    }

    // Product flavors for pack inclusion
    flavorDimensions += "content"
    productFlavors {
        create("withPacks") {
            dimension = "content"
            versionNameSuffix = "-withPacks"
        }
        create("withoutPacks") {
            dimension = "content"
            versionNameSuffix = "-withoutPacks"
        }
    }

    // Configure asset sources per flavor
    sourceSets {
        getByName("main") {
            // Base assets - resources and scripts (symlinked)
            assets.srcDirs("src/main/assets")
        }
        getByName("withPacks") {
            // Additional assets for withPacks flavor
            // The packs symlink will be created in assets directory
        }
    }

    signingConfigs {
        create("release") {
            // Load signing config from local.properties or environment variables
            val localProperties = org.jetbrains.kotlin.konan.properties.Properties()
            val localPropertiesFile = rootProject.file("local.properties")
            if (localPropertiesFile.exists()) {
                localPropertiesFile.inputStream().use { localProperties.load(it) }
            }

            val keystorePath = localProperties.getProperty("keystorePath")
                ?: System.getenv("RELEASE_STORE_FILE")

            // Only set signing config if keystore path is provided
            if (keystorePath != null && keystorePath.isNotEmpty()) {
                storeFile = file(keystorePath)
                storePassword = localProperties.getProperty("keystorePassword")
                    ?: System.getenv("RELEASE_STORE_PASSWORD")
                keyAlias = localProperties.getProperty("keyAlias")
                    ?: System.getenv("RELEASE_KEY_ALIAS")
                keyPassword = localProperties.getProperty("keyPassword")
                    ?: System.getenv("RELEASE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Use signing config only if keystore is valid
            val releaseSigningConfig = signingConfigs.getByName("release")
            if (releaseSigningConfig.storeFile?.exists() == true) {
                signingConfig = releaseSigningConfig
            }
        }
        debug {
            isDebuggable = true
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}
