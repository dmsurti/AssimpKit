===============
Getting Started
===============

Requirements
============
* Xcode 8.0 or later
* ObjC 2.0
* iOS 10.0 or later
* macOS 10.11 or later

.. _installation-label:

Installation
============

AssimpKit is `Carthage`_ compatible.

To install with Carthage, follow the instructions on Carthage.

Your application Cartfile should have the following entry for AssimpKit::

    github "dmsurti/AssimpKit"

After carthage update, add the appropriate platform framework (iOS, macOS) to your project. The frameworks are placed in iOS and Mac subdirectories under the ``Carthage/Build`` directory of your project.

Important Build Setting for iOS applications only
-------------------------------------------------

If you are developing an iOS application, set the ``Enable Bitcode`` under ``Build
Settings->Build Options`` of your target to NO.

.. _api-overview-label:

API Overview
============

Table below lists the important clasess in AssimpKit.

+----------------------+------------------------------------------------------------+
|Class/Category        | Description                                                |
+----------------------+------------------------------------------------------------+
|SCNScene(AssimpImport)| The container for all SceneKit content, loaded with assimp.|
+----------------------+------------------------------------------------------------+
|SCNNode(AssimpImport) | The node category to add animation to a node.              |
+----------------------+------------------------------------------------------------+

You can use the AssimpImport category defined on SCNScene to load scenes. The post
processing steps that the assimp library can apply to the imported data are
listed at AssimpKitPostProcessSteps.

The imported SCNAssimpScene contains a model SCNScene which represents the 3D
model and the skeleton if it contains one, in addition to the array of
animations each represented by an SCNScene object. The SCNAssimpScene also
contains the key names for the animations which can be used when adding,
removing animations.

The AssimpImport category defined on SCNScene and SCNNode also contain a method
to add a skeltal animation.

For more information, refer to the Tutorial.


.. _Carthage: https://github.com/Carthage/Carthage
