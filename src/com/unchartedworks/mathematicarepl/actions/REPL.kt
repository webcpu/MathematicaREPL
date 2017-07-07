package com.unchartedworks.mathematicarepl.actions

import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.PlatformDataKeys
import com.intellij.openapi.fileEditor.FileDocumentManager
import com.intellij.openapi.project.Project
import com.intellij.psi.search.FilenameIndex
import com.intellij.psi.search.GlobalSearchScope
import io.reactivex.rxkotlin.subscribeBy
import io.reactivex.rxkotlin.toObservable
import java.io.File
import java.io.IOException
import java.net.ConnectException
import java.net.URL

/**
* Created by liang on 20/05/2017.
*/
class REPL : AnAction() {
    override fun update(event: AnActionEvent) {
        event.presentation.isEnabled = event.getData(PlatformDataKeys.EDITOR) != null
    }

    override fun actionPerformed(event: AnActionEvent?) = process(event)

    fun process(event: AnActionEvent?) {
        val list = listOf(getFile(event))
        list.toObservable()
                .filter { mathematicaFileQ(it) }
                .map { saveFileList(event, it) }
                .subscribeBy(
                        onNext = { run(event) },
                        onError = { it.printStackTrace() },
                        onComplete = { println("Done!") }
                )
    }

    fun getFile(event: AnActionEvent?): String {
        val editor = event?.getData(PlatformDataKeys.EDITOR)
        val filePath = FileDocumentManager.getInstance().getFile(editor!!.document)!!.path
        return filePath
    }

    private fun mathematicaFileQ(filePath: String): Boolean {
        val fileExtension = { filename: String -> filename.substringAfterLast(".") }
        return fileExtension(filePath) == "m"
    }

    private fun run(event: AnActionEvent?) {
        try {
            runFromWeb()
        } catch (e: ConnectException) {
            runFromScript(event)
        } catch (e: IOException) {

        }
    }
}

fun runFromScript(event: AnActionEvent?) {
    val notebooks = getNotebooks(event)
    val hasREPLNotebook = notebooks.count() > 0
    val notebook = if (hasREPLNotebook) {" " + notebooks.first()} else {""}
    val runPath = classesPath() + "run.wl"
    val command = if (hasREPLNotebook) {arrayOf(runPath, notebook)} else {arrayOf(runPath)}

    println("runFromScript")
    Runtime.getRuntime().exec(command, null, File(classesPath()))
}

//    private fun sendNotification(content: String) {
//        val notification = Notification("", "Info", content, NotificationType.INFORMATION)
//        Notifications.Bus.notify(notification)
//    }

private fun saveFileList(event: AnActionEvent?, filePath: String): String {
    val filelist = getProjectRoot(event)!! + "/filelist"
    val content  = filePath + "\n"
    File(filelist).writeText(text = content)
    return filelist
}

//    private fun getProjectFiles(event: AnActionEvent?): List<String> {
//        val project = getProject(event)
//        val files   = FilenameIndex.getAllFilesByExt(project!!, "m", GlobalSearchScope.projectScope(project!!)).map { it.path }
//        return files
//    }

private fun getNotebooks(event: AnActionEvent?): List<String> {
    val project = getProject(event)
    val files   = FilenameIndex.getAllFilesByExt(project!!, "nb", GlobalSearchScope.projectScope(project)).map { it.path }
    return files.filter { REPLNotebookQ(it)}
}

private fun REPLNotebookQ(notebook: String): Boolean {
    val content = File(notebook).readText()
    return content.contains("CellTags->\"LOADER\"")
}

private fun getProject(event: AnActionEvent?): Project? = event?.getData(PlatformDataKeys.PROJECT)

private fun getProjectRoot(event: AnActionEvent?): String? {
    val project: Project? = getProject(event)
    return project!!.basePath
}

private fun runFromWeb(): String {
    val localhost   = URL(serverURLString())
    val connection  = localhost.openConnection()
    val content     = connection.getInputStream().bufferedReader().use { it.readText() }
    println("runFromWeb: $localhost")
    return content
}

