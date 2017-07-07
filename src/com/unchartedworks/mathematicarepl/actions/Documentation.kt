package com.unchartedworks.mathematicarepl.actions

import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.PlatformDataKeys
import com.intellij.openapi.editor.Editor
import com.intellij.psi.PsiElement
import com.intellij.psi.util.PsiUtilBase
import java.io.IOException
import java.net.ConnectException
import java.net.URL

/**
* Created by liang on 07/06/2017.
*/
class Documentation : AnAction() {
    override fun actionPerformed(event: AnActionEvent) {
        val text = getElementText(event) ?: ""
        helpLookup(event, text)
    }

    private fun getElementText(event: AnActionEvent): String? {
        val editor: Editor       = event.getData(PlatformDataKeys.EDITOR) ?: return null
        val element: PsiElement? = PsiUtilBase.getElementAtCaret(editor)
        return element?.text
    }

    private fun helpLookup(event: AnActionEvent, keyword: String) {
        try {
            helpLookupFromWeb(keyword)
        } catch (e: ConnectException) {
            helpLookupFromScript(event, keyword)
        } catch (e: IOException) {

        }
    }

    private fun helpLookupFromWeb(keyword: String): String {
        val localhost = URL(serverURLString() + "?" + keyword)
        val connection = localhost.openConnection()
        val content = connection.getInputStream().bufferedReader().use { it.readText() }
        return content
    }

    private fun helpLookupFromScript(event: AnActionEvent, keyword: String) = Unit
}

