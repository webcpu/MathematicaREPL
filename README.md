# MathematicaREPL for IntelliJ IDEA (macOS only)
## Introduction
MathematicaREPL allows you to evaluate your Mathematica code from Intellij IDEA and display results in a Mathematica notebook. This is a missing feature of Mathematica Support plugin. 

Key features of the MathematicaREPL include:
- REPL                                      ⌘5  or ⌘R

	Evaluates code and display results in Mathematica notebook.
- Find Selected Function     ⇧⌘F

	Opens documentation about the selected function.
![](https://user-images.githubusercontent.com/4646838/27966861-15a56e76-6341-11e7-85c2-9a6907277f33.gif)

## Binary Installation
### System Requirements
- macOS Serria
- Intellij IDEA
- Mathematica 11.0 or later

### Install MathematicaREPL plugin
1. Download the latest MathematicaREPL.zip. 

	[ https://github.com/unchartedworks/MathematicaREPL/releases ]
2. Open the Preferences dialog (e.g. ⌘,).
3. In the left-hand pane, select Plugins.
4. In the right-hand pane, click Install plugin from disk… button.
5. Select the downloaded MathematicaREPL.zip and click Open button.
6. Click OK button and then click Restart button to restart Intellij IDEA.
![](https://user-images.githubusercontent.com/4646838/27966944-6aac1550-6341-11e7-9d85-ed84a9c8ef9d.png)

### Configure Intellij IDEA
Please make sure your Intellij IDEA’s keymap is Mac OS X 10.5+, otherwise the shortcuts above might not work. 

#### Select Keymap
1. Open the Preferences dialog (e.g. ⌘,).
2. In the left-hand pane, select Keymap.
3. In the rich-hand pane, select the "Mac OS X 10.5+" from the dropdown.
![](https://user-images.githubusercontent.com/4646838/27966945-6aaf20d8-6341-11e7-8105-e07dc2911a4c.png)

#### Solve shortcut conflict
⌘R is the preferred shortcut to evaluate code, however ⌘R is a predefined shortcut in keymap “Mac OS X 10.5+”, if you want to use ⌘R to evaluate code, you can just remove the shortcut for “Replace” in keymap “Mac OS X 10.5+”, otherwise you can use ⌘5 instead.
![](https://user-images.githubusercontent.com/4646838/27966946-6aaf70d8-6341-11e7-80a9-ef1dadbb25db.png)
## Set up
1. Download the Workbench template project Hello.zip. 
	[ https://github.com/unchartedworks/MathematicaREPL/releases ]
3. Unzip Hello.zip
4. Run Intellij IDEA and open directory Hello.
5. Select Hello.m
	![](https://user-images.githubusercontent.com/4646838/27967353-01ccd40a-6343-11e7-9f63-9213dd1f6e95.png)
7. Press ⌘R  to evaluate Hello.m.
	![](https://user-images.githubusercontent.com/4646838/27967462-73bc4078-6343-11e7-8858-d7c3798974a4.png)
