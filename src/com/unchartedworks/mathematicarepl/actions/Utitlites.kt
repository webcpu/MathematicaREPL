package com.unchartedworks.mathematicarepl.actions

import org.json.JSONObject
import java.io.File

/**
* Created by liang on 09/06/2017.
*/

fun serverURLString(): String {
    val defaults = Defaults.instance()
    val host = defaults["host"]
    val port = defaults["port"].toString()
    return "http://$host:$port/"
}

object Defaults {
    fun instance(): JSONObject {
        val path = classesPath() + "/defaults.json"
        val content = File(path).readText()
        return JSONObject(content)
    }
}