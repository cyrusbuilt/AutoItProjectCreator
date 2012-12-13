AutoItProjectCreator
Ver 1.0.0.4
By Chris Brunner (CyrusBuilt)
Released under GPL v2

The purpose of this tool is to provide the ability to create and edit AutoIt3 "projects".  An AutoIt3 "project" typically consists of a folder structure,
a project definition file (*.au3proj) and at least one AutoIt3 script (main script) file.  The folder structure will vary based on the type of "project"
being created.

Currently, the following project types are support:
A) Library script
B) Application script

A "Library script" is basically an include.  It is script containing common functions and/or constants meant to be used with other scripts
by including them using the #include directive.  An application script is a script meant to carry out a task or series of task.  This can be either
a CLI or GUI application, or just a plain script that carries out its actions with no UI at all.

Description of files unpacked by the installer:
au3.properties.aipc32 - or - au3.properties.aipc64 - A replacement au3.properties file for SciTE that contains tool menu entries for creating
or opening AutoIt3 projects.  You will have one or the other depending on which installer you used (32 or 64bit).

AutoItProjectCreator.au3 - The uncompiled script source file for AutoItProjectCreator.

AutoItProjectCreator.ini - The global configuration file for AutoItProjectCreator.

AutoItProjectCreator32.exe - or - AutoItProjectCreator64.exe - The compiled script application for AutoItProjectCreator.  You will have one 
or the other depending on which installer you used (32 or 64bit).

BaseApplicationConfig.ini - This file is an example of an application script configuration file in standard INI format.

BaseProjectDefinition.au3proj - This is an example of a project definition file.

licenst.txt - A copy of the GPL v2 license.

readme.txt - You are reading it!

Important note:
The installer was developed using NSIS (Nullsoft Scriptable Install System).  The installers and uninstallers themselves are 32bit executables,
regardless of whether they have a *32 or *64 designation in the filename.  The difference is that they either install the 64bit or 32bit executables
and (if the user chooses) the 32bit or 64bit version of the au3.properties file.  If the user chooses to integrate, the the existing au3.properties
file is renamed to au3.properties.old in the properties folder, and then the either au3.properties.aipc32 or au3.properties.aipc64 is unpacked to the
properties folder and renamed to au3.properties.  The installer will associate the *.au3proj file extension with AutoItProjectCreator.  Likewise,
uninstalling AutoItProjectCreator will disassociate the file extension and restore the original au3.properties file.