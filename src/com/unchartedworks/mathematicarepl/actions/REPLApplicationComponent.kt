package com.unchartedworks.mathematicarepl.actions

import com.intellij.openapi.application.PathManager
import com.intellij.openapi.components.ApplicationComponent
import java.io.File

/**
* Created by liang on 05/06/2017.
*/
class REPLApplicationComponent : ApplicationComponent {

    override fun initComponent() {
        println("initComponent")
        setup()
    }

    override fun disposeComponent() {
    }

    override fun getComponentName() = "com.unchartedworks.mathematicarepl.actions.REPLApplicationComponent"
}

/* com.unchartedworks.mathematicarepl.actions.setup */
private fun setup() {
    extractJar()
    addPermissions()
    installREPLPackage()
}
/* extract Jar */
private fun extractJar() {
    if (!isSandbox()) {
        removeClasses()
        makeDestDir()
        _extractJar()
    }
}

private fun removeClasses() {
    val command = arrayOf("/bin/rm", "-rf", classesPath())
    exec(command)
}

private fun makeDestDir() {
    val destDir = classesPath()
    File(destDir).mkdirs()
}

private fun _extractJar() {
    val destDir = classesPath()
    val jarFile = pluginRootPath() + "lib/MathematicaREPL.jar"
    val command = arrayOf("/usr/bin/unzip","-d", destDir, jarFile)
    val runtime = Runtime.getRuntime()
    runtime.exec(command, null).waitFor()
}

/* add permissions */
private fun addPermissions() {
    val files = arrayOf("installpackage.wl", "run.wl", "activatemma.scpt")
    files.map {
        val path = classesPath() + it
        addExecutablePermission(path)
    }
}

private fun addExecutablePermission(path: String) {
    val command = arrayOf("/bin/chmod", "0755", path)
    exec(command)
}

/* install package */
private fun installREPLPackage() {
    val path                = classesPath() + "installpackage.wl"
    val command             = arrayOf(path)
    val workingDirectory    = File(classesPath())
    val runtime             = Runtime.getRuntime()
    runtime.exec(command, null, workingDirectory).waitFor()
}

/* plugin root path */
fun pluginRootPath() : String {
    val path = PathManager.getPluginsPath()
    return path + "/MathematicaREPL/"
}

/* classes root path */
fun classesPath() : String {
    return if (isSandbox()) sandboxClassesPath() else productionClassesPath()
}

private fun productionClassesPath() : String {
    val path = System.getProperty("user.home")
    return path + "/.MathematicaREPL/"
}

private fun sandboxClassesPath() : String {
    val path = PathManager.getPluginsPath()
    return path + "/MathematicaREPL/classes/"
}

/* com.unchartedworks.mathematicarepl.actions.exec */
fun exec(command: Array<String>) {
    Runtime.getRuntime().exec(command, null)
}

/* com.unchartedworks.mathematicarepl.actions.isSandbox */
fun isSandbox(): Boolean {
    return pluginRootPath().contains("/plugins-sandbox/plugins")
}
