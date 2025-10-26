buildscript {
    repositories {
        google()
        mavenCentral() // Replaced jcenter() with mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.3") // Use Kotlin DSL syntax and version 4.4.2

    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}