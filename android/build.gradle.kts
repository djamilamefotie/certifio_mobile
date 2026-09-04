// Optimisations pour accélérer la compilation
if (rootProject == project) {
    rootProject.ext.set("kotlin.incremental", true)
    rootProject.ext.set("org.gradle.parallel", true)
    rootProject.ext.set("org.gradle.workers.max", (Runtime.getRuntime().availableProcessors() / 2).toInt())
    rootProject.ext.set("android.useAndroidX", true)
    rootProject.ext.set("android.enableJetifier", false)
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Résolution des conflits de dépendances (downgrade versions)
    configurations.all {
        resolutionStrategy {
            force("androidx.fragment:fragment:1.6.0")
            force("androidx.window:window:1.1.0")
            force("androidx.activity:activity:1.8.0")
            force("androidx.lifecycle:lifecycle-livedata-core-ktx:2.6.2")
            force("androidx.lifecycle:lifecycle-livedata:2.6.2")
            force("androidx.lifecycle:lifecycle-viewmodel:2.6.2")
            force("androidx.lifecycle:lifecycle-livedata-core:2.6.2")
            force("androidx.lifecycle:lifecycle-viewmodel-savedstate:2.6.2")
            force("androidx.core:core-ktx:1.12.0")
            force("androidx.core:core:1.12.0")
            force("androidx.lifecycle:lifecycle-runtime:2.6.2")
            force("androidx.lifecycle:lifecycle-process:2.6.2")
            force("androidx.exifinterface:exifinterface:1.3.7")
            force("androidx.annotation:annotation-experimental:1.3.1")
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
