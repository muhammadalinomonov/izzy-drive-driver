
import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory
import org.gradle.api.provider.Provider


// 1) Configure repositories for all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }

}

// 2) Redirect the root build dir to ../../build
val customRootBuildDir: Provider<Directory> = rootProject.layout.buildDirectory.dir("../../build")
rootProject.layout.buildDirectory.set(customRootBuildDir)

// 3) For each subproject, point its build dir inside the custom root build dir
subprojects {
    // Ensure :app is evaluated first
    evaluationDependsOn(":app")

    // Set this subproject's build directory
    val subprojectBuildDir = customRootBuildDir.map { it.dir(project.name) }
    project.layout.buildDirectory.set(subprojectBuildDir)
}

// 4) A top-level clean task that wipes out our custom build dir
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}