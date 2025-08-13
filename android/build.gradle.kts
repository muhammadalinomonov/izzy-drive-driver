import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory
import org.gradle.api.provider.Provider

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.6.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

// 1) Configure repositories for all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }

}
//
//val customRootBuildDir: Provider<Directory> = rootProject.layout.buildDirectory.dir("../../build")
//rootProject.layout.buildDirectory.set(customRootBuildDir)
//
//subprojects {
//    val subprojectBuildDir = customRootBuildDir.map { it.dir(project.name) }
//    project.layout.buildDirectory.set(subprojectBuildDir)
//}


//val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
//rootProject.layout.buildDirectory.value(newBuildDir)


subprojects {
    project.evaluationDependsOn(":app")
}
// 4) A top-level clean task that wipes out our custom build dir
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}