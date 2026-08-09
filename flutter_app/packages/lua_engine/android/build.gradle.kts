plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.nagarikpatro.lua_engine"
    compileSdk = 34

    defaultConfig {
        // Lua is compiled with LUA_USE_POSIX, whose file layer calls fseeko /
        // ftello. Bionic only declares those from API 24, so building against
        // 21 fails to compile liolib.c. Android 7.0 is the real floor for this
        // plugin.
        minSdk = 24

        externalNativeBuild {
            cmake {
                cppFlags("-std=c++17")
            }
        }
        ndk {
            // Match flutter.ndkVersion from host app
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    externalNativeBuild {
        cmake {
            path = file("CMakeLists.txt")
            version = "3.22.1"
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
}
