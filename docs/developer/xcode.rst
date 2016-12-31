====================
XCode Project Layout
====================

The XCode project is laid out such that the common cross platform code related
to reading using Assimp and transforming it to a Scene Kit scene graph is reused
for both the iOS and macOS platforms. The testing code is similary reused for
both the platforms.

.. image:: ../img/xcode-layout.*

Common Code
-----------

The common code, including both sources and tests, is placed under
`Code/Model`_. This common code is then used in 4 targets, 2 of which ship the
iOS and macOS frameworks while the other two are testing targets.

Targets
-------

The project contains the following 4 targets.

AssimpKit-iOS
~~~~~~~~~~~~~

This target builds the ``AssimpKit.framework`` for the iOS platform using the common code.

AssimpKit-macOS
~~~~~~~~~~~~~~~

This target builds the ``AssimpKit.framework`` for the macOS platform using the
common code.

AssimpKitTests_iOS
~~~~~~~~~~~~~~~~~~

This target tests the common code using the test `assets`_ for the iOS platform.

AssimpKitTests_macOS
~~~~~~~~~~~~~~~~~~~~

This target tests the common code using the test `assets`_ for the macOS platform.

Example Apps
------------

The library also contains 2 example apps `iOS-Example.xcodeproj`_ and
`OSX-Example.xcodeproj`_ which are configured for the ``AssimpKit.framework``
depedency. You can read more about the :ref:`example-apps`.

Changing Code
~~~~~~~~~~~~~

Any code change either for fixing a bug or adding a new feature, should ideally result in updates to the test code as well as example apps.

.. _Code/Model: https://github.com/dmsurti/AssimpKit/tree/master/Code/Model
.. _assets: https://github.com/dmsurti/AssimpKit/tree/master/AssimpKit/assets
.. _iOS-Example.xcodeproj: https://github.com/dmsurti/AssimpKit/tree/master/AssimpKit/Library/iOS-Example
.. _OSX-Example.xcodeproj: https://github.com/dmsurti/AssimpKit/tree/master/AssimpKit/Library/OSX-Example
