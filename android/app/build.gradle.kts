plugins {
        id("com.android.application")
        // START: FlutterFire Configuration
        id("com.google.gms.google-services")
        // END: FlutterFire Configuration
        id("kotlin-android")
        // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
        id("dev.flutter.flutter-gradle-plugin")
    }

    android {
        namespace = "com.example.online_edu_app_flutter"
        compileSdk = flutter.compileSdkVersion

        // ИЗМЕНЕНИЕ №1: Указываем точную версию NDK, как просила ошибка
        ndkVersion = "27.0.12077973"

        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_11
            targetCompatibility = JavaVersion.VERSION_11
        }

        kotlinOptions {
            jvmTarget = JavaVersion.VERSION_11.toString()
        }

        sourceSets {
            getByName("main") {
                java.srcDirs("src/main/kotlin")
            }
        }

        // ВСТАВЬТЕ ЭТОТ БЛОК СЮДА
        flavorDimensions += "app" // Добавляем измерение "app"

        productFlavors {
            create("student") {
                dimension = "app"
                applicationIdSuffix = ".student" // Добавляем суффикс к ID для пользовательского приложения
                versionNameSuffix = "-student"
                // Настройка для пользовательского приложения
            }
            create("admin") {
                dimension = "app"
                applicationIdSuffix = ".admin" // Добавляем суффикс к ID для админ-приложения
                versionNameSuffix = "-admin"
                // Настройка для админ-приложения
            }
        }

        defaultConfig {
            applicationId = "com.example.online_edu_app_flutter"

            // ИЗМЕНЕНИЕ №2: Устанавливаем минимальную версию SDK, как просила ошибка
            minSdk = 23 // <-- Заменяем flutter.minSdkVersion на 23

            targetSdk = flutter.targetSdkVersion
            versionCode = flutter.versionCode
            versionName = flutter.versionName
        }

        buildTypes {
            release {
                signingConfig = signingConfigs.getByName("debug")
                ndk {
                // Эта строка говорит Flutter включать только 64-битные библиотеки
                abiFilters += listOf("arm64-v8a") 
            }
            }
        }
    }

    flutter {
        source = "../.."
    }
