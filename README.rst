==========================================================
The Luau Version of The Ren'Py Visual Novel Engine, LuaRpy
==========================================================

LuaRpy is an attempt to recreate the Ren'Py Visual Novel Engine and port it over to `Roblox's Luau.
<https://github.com/luau-lang/luau/>`_

Some things may be inaccurate or changed due to Luau's limitations.
THIS PRODUCT IS HEAVILY BEING WORKED ON.

Getting Started
===============


*(Be sure to disable CharacterAutoLoads in Players and disable StreamingEnabled in Workspace)*


The main module, LuaRpy
-----------------------


Create a *ModuleScript* in ReplicatedStorage, name it *LuaRpy* and port over the "LuaRpy.luau" code from this repository.

**LuaRpy** is the entire engine to handle the logic and system of your visual novel.


Game handler module
-------------------


Create a *ModuleScript* named *Handler* in *ReplicatedStorage.*
 
Alongside this, create two *ModuleScripts* inside of Handler and name one to *"DefinableObjects"* and the other to *"Story"*. 

*(p.s. this can be changed if you wish to have chapters.)*

Now, inside of the Handler script, return a function and add the globals above it:

.. code-block:: luau
  :linenos:
  
  _G.project_version = "0.0.1"
  _G.project_name = "your project name here"
  _G.dialogSpeed = 1

  return function(): ()
  
  end

Inside of the function, require LuaRpy:

.. code-block:: luau
  :linenos:
  
  local LuaRpy = require(path.to.LuaRpy).new({
    menu = YourPlayerGui.MainMenu,
    primary = PlayerGui.Primary
  })

With this, you can now call the LuaRpy essential functions and start your game.

A simple story script:

.. code-block:: luau
  :linenos:
  
  for i = LuaRpy.SCENE_COUNT, #Story do
  LuaRpy:doScene(Story[i])
		
  if not Story[i].NO_INPUT then
    LuaRpy:waitForInput()
    if LuaRpy.typeWriting then
      LuaRpy.typeWriting = nil
      LuaRpy:waitForInput()
    end
  end
  end

The initializer
------------

Create a LocalScript inside of ReplicatedFirst. This script can have any name.

Inside of the script, add this code:
  
.. code-block:: luau
  :linenos:
  
  game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
  game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
  require(game:GetService("ReplicatedStorage"):WaitForChild("Handler"))() -- handler must return a function.


User Interface
--------------


Download the "gameInterface.rbxm" file as a template for your interface. Place this in StarterGui and ungroup it. 

You may customize this to your liking.


Too lazy to follow?
-------------------
Download the "defaultTemplate.rbxl" file and modify everything to your needs.

Contributing
============

If you wish to contribute by fixing a bug, improving the documentation or adding a simple feature, create a pull request.
Create an issue if you want to make a major change.


Credits
=======

`The Ren'Py Visual Novel Engine team
<https://github.com/renpy>`_ for creating Ren'Py itself.

https://www.renpy.org/
