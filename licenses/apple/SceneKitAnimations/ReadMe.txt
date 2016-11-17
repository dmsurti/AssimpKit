### Scene Kit Animations ###

===========================================================================
DESCRIPTION:

Demonstrates how to use Scene Kit to load a 3D scene and select animations to play. It shows how to programmatically retrieve animations and play them when a button is pressed.

===========================================================================
PACKAGING LIST:

ASCAppDelegate.h/m
This is the main controller for the application and handles the loading of a initial scene and its related animations. This class uses an IBOutlet to reference an SCNView instance in MainMenu.xib which was configured in Interface Builder to have an initial scene, a custom background color and the default lighting enabled. In addition four buttons have their actions set to play the animations that were loaded, configured and stored by the App Delegate.

===========================================================================
Copyright (C) 2012 Apple Inc. All rights reserved.
