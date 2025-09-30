plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.precifica"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "dev.vinisebold.precifica"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Verifica se as credenciais do keystore estão disponíveis (CI/CD)
    val keystorePath = System.getenv("KEY_STORE_FILE")
    val storePass = System.getenv("KEY_STORE_PASSWORD")
    val alias = System.getenv("KEY_ALIAS")
    val keyPass = System.getenv("KEY_PASSWORD")
    
    val hasKeystoreConfig = !keystorePath.isNullOrBlank() && 
                            !storePass.isNullOrBlank() && 
                            !alias.isNullOrBlank() && 
                            !keyPass.isNullOrBlank()

    signingConfigs {
        if (hasKeystoreConfig) {
            // Release signing fed by environment variables in CI (GitHub Actions)
            create("release") {
                val keystoreFile = file(keystorePath!!)
                if (keystoreFile.exists()) {
                    storeFile = keystoreFile
                    storePassword = storePass
                    keyAlias = alias
                    keyPassword = keyPass
                    println("[gradle] ✓ Usando release keystore para produção: $keystorePath")
                } else {
                    throw GradleException("ERRO: Keystore não encontrado em $keystorePath")
                }
            }
        } else {
            println("[gradle] ⚠ Variáveis de keystore não definidas - build de desenvolvimento (usando debug keystore)")
        }
    }

    buildTypes {
        release {
            // Usa release signing apenas se configurado, senão usa debug (desenvolvimento local)
            signingConfig = if (hasKeystoreConfig) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}
