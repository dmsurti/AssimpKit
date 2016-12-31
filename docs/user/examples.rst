.. _example-apps:

============
Example Apps
============

The library source code on `GitHub repo`_ ships with two example apps, for iOS and macOS platforms, which demonstrate the use of this API.

Build Instructions for the example apps
---------------------------------------

* Checkout the source code from `GitHub repo`_.
* Open the ``iOS-Example.xcodeproj`` for the iOS example app.
* Open the ``OSX-Example.xcodeproj`` for the macOS example app.
* Clean, Build in XCode.

About the iOS example app
-------------------------

This example app has ``Application supports iTunes file sharing`` property enabled in it's ``plist`` file, which allows you to use iTunes to upload your 3D models to your device.

Once you have uploaded the 3D models, you can view the models as such.

Step 1
~~~~~~

You can pick the model to view. You can also skip picking a model and navigate to
picking only a 3D skeletal animation.


.. image:: ../img/iOS-app1.*

Step 2
~~~~~~

You can pick a 3D animation in this step. You can skip this step if you just want to view the 3D model selected in step 1.

.. image:: ../img/iOS-app2.*

Step 3
~~~~~~

Based on your selection, you can view only the model, the skeletal animation or both.

.. image:: ../img/iOS-app3.*

About the macOS example app
---------------------------

This example app allows you to select the 3D model and animation files using the
file picker.

Step 1
~~~~~~

You can pick the model to view. You can also skip picking a model and instead
pick only a 3D skeletal animation.

.. image:: ../img/macOS-app1.*

Step 2
~~~~~~

You can pick a 3D animation in this step. You can skip this step if you just
want to view the 3D model selected in step 1.

.. image:: ../img/macOS-app2.*

Step 3
~~~~~~

Based on your selection, you can view only the model, the skeletal animation or both.

.. image:: ../img/macOS-app3.*

..  _Github repo: https://github.com/dmsurti/AssimpKit 

