========
Tutorial
========

Install the ``AssimpKit.framework`` following the :ref:`installation-label` guide.

It is recommended to go through the :ref:`api-overview-label`, before working
through the tutorial.

Load a 3D model
===============

Load a Scene which is a part of your app bundle
-----------------------------------------------

You can load a scene which is a part of your app bundle, as in Listing I-1 below.

*Listing I-1: Load a scene which is part of your app bundle*::

    #import <AssimpKit/PostProcessing.h>
    #import <AssimpKit/SCNScene+AssimpImport.h>

    NSString *spider = @"spider.obj";

    // Start the import on the given file with some example postprocessing
    // Usually - if speed is not the most important aspect for you - you'll
    // probably request more postprocessing than we do in this example.
    SCNAssimpScene* scene =
        [SCNScene sceneNamed:spider
            postProcessFlags:AssimpKit_Process_FlipUVs |
                             AssimpKit_Process_Triangulate]];

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the model scene to the view
    scnView.scene = scene.modelScene;

Load a scene by specifying a file URL
-------------------------------------
                    
You can load a scene by specifying a file URL, as in Listing I-2 below.

*Listing I-2: Load a scene with a file URL*::

    #import <AssimpKit/PostProcessing.h>
    #import <AssimpKit/SCNScene+AssimpImport.h>

    // The path to the file path must not be a relative path
    NSString *soldierPath = @"/assets/apple/attack.dae";

    // Start the import on the given file with some example postprocessing
    // Usually - if speed is not the most important aspect for you - you'll
    // probably request more postprocessing than we do in this example.
    SCNAssimpScene *scene = 
        [SCNScene assimpSceneWithURL:[NSURL URLWithString:soldierPath]
                    postProcessFlags:AssimpKit_Process_FlipUVs |
                                     AssimpKit_Process_Triangulate]];

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the model scene to the view
    scnView.scene = scene.modelScene;

Load Skeletal Animations
========================

AssimpKit builds on top of the skeletal animation support provided by SceneKit.
For any scene that contains skeletal animation data, it creates a skinner and
sets it to the node whose geometry the skinner deforms. The animated scene after
importing will contain a set of animations each with a unique animation key. You
only have to add the animation to the scene to play it, without even worrying
about which node to add the animation.

AssimpKit supports skeletal animations irrespective of whether they are defined
in one animation file or multiple animation files.

Load an animation which is defined in the same file
---------------------------------------------------

You can load an animation which is defined in the same file as the model you are
animating, using the listing I-3 below.

*Listing I-3: Load and play an animation which is defined in the same file*::

    #import <AssimpKit/PostProcessing.h>
    #import <AssimpKit/SCNScene+AssimpImport.h>

    // The path to the file path must not be a relative path
    NSString *boyPath = @"/of/assets/astroBoy_walk.dae";

    // Start the import on the given file with some example postprocessing
    // Usually - if speed is not the most important aspect for you - you'll
    // probably request more postprocessing than we do in this example.
    SCNAssimpScene *scene = 
        [SCNScene assimpSceneWithURL:[NSURL URLWithString:boyPath];
                    postProcessFlags:AssimpKit_Process_FlipUVs |
                                     AssimpKit_Process_Triangulate]];

    // get the animation which is defined in the same file
    NSString *walkID = @"astroBoy_walk-1";
    SCNScene *walkAnim = [scene animationSceneForKey:walkAnim];

    // add the walk animation to the boy model scene
    [scene.modelScene addAnimation:attackAnim];

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the model scene to the view
    scnView.scene = scene.modelScene;

Load an animation which is defined in a seprate file
----------------------------------------------------

You can load an animation which is defined in a separate file from the model you
are animating, using the listing I-5 below.

*Listing I-4: Load and play an animation which is defined in a separate file*::

    #import <AssimpKit/PostProcessing.h>
    #import <AssimpKit/SCNScene+AssimpImport.h>

    // The path to the file path must not be a relative path
    NSString *explorer = @"/assets/apple/explorer_skinned.dae";

    // Start the import on the given file with some example postprocessing
    // Usually - if speed is not the most important aspect for you - you'll
    // probably request more postprocessing than we do in this example.
    SCNAssimpScene *scene =
        [SCNScene assimpSceneWithURL:[NSURL URLWithString:explorer]
                    postProcessFlags:AssimpKit_Process_FlipUVs |
                                     AssimpKit_Process_Triangulate];

    // load an animation which is defined in a separate file
    NSString *jumpAnim = @"/explorer/jump_start.dae"];
    SCNAssimpScene *jumpStartScene =
        [SCNAssimpScene assimpSceneWithURL:[NSURL URLWithString:jumpAnim]
                          postProcessFlags:AssimpKit_Process_FlipUVs |
                                           AssimpKit_Process_Triangulate];

    // get the aniamtion with animation key
    NSString *jumpId = @"jump_start-1";
    SCNScene *jumpStartAnim = [jumpStartScene animationSceneForKey:jumpId];

    // add the jump animation to the explorer scene
    [scene.modelScene addAnimation:jumpStartAnim];

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the model scene to the view
    scnView.scene = scene.modelScene;

Adding an animation to a node
-----------------------------

You can also add an animation to a node, using the SCNNode(AssimpImport) category.

*Listing I-5: Load and play an animation added to SCNNode*::

    #import <AssimpKit/PostProcessing.h>
    #import <AssimpKit/SCNScene+AssimpImport.h>

    // Some node somewhere to which you add the animation
    SCNNode *targetNode = ...
    
    // load an animation which is defined in a separate file
    NSString *jumpAnim = @"/explorer/jump_start.dae"];
    SCNAssimpScene *jumpStartScene =
        [SCNAssimpScene assimpSceneWithURL:[NSURL URLWithString:jumpAnim]
                          postProcessFlags:AssimpKit_Process_FlipUVs |
                                           AssimpKit_Process_Triangulate];

    // get the aniamtion with animation key
    NSString *jumpId = @"jump_start-1";
    SCNScene *jumpStartAnim = [jumpStartScene animationSceneForKey:jumpId];

    // add the jump animation to the explorer scene
    [targetNode addAnimation:jumpStartAnim];

Removing Animations
-------------------

You can use the `removeAllAnimations`_ method defined in ``SCNAnimatable`` to
remove all animations attached to the object, using AssimpKit.

Serialization and integrating with asset pipeline
=================================================

You can serialize the model and animation scenes in SCNAssimpScene using the
`write`_ defined in `SCNScene` to export to either `.scn` or `.dae` file. See
the discussion section of `write`_ for more details.

By exporting using the above serialization method, you can both edit the
exported assets in XCode's scene editor and also integrate the assets imported
into your application's asset pipeline.

.. image:: ../img/kit.*

.. _using-exported-scn:

Using ``.scn`` archives exported from AssimpKit in your app
===========================================================

Assuming you have two files in the ``Quake .md5`` format, ``Bob.md5mesh`` which
contains the 3D model data and ``Bob.md5anim`` which contains a skeletal
animation. Using the API as explained above, you can load both the model
``SCNScene`` and animation ``SCNScene`` and then export these to the native
``.scn`` archive format.

Assume ``Bob.md5mesh`` is exported to ``Bob.scn`` and ``Bob.md5anim`` is
exported to ``Bob-1.scn``, then in some ``iOS/macOS`` app,
you can load these and play the animation as such.::

     #import <AssimpKit/SCNScene+AssimpImport.h>

     SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/Bob.scn"];
     SCNScene *animScene = [SCNScene sceneNamed:@"art.scnassets/Bob-1.scn"];
     [scene addAnimationScene:animScene];

You can see below the ``Bob.scn`` file edited in XCode Scene editor.

.. image:: ../img/bob-XCode.*

The edited ``Bob.scn`` with animation rendered.

.. image:: ../img/bob-iOS.*

.. _removeAllAnimations: https://developer.apple.com/reference/scenekit/scnanimatable/1522762-removeallanimations
.. _write: https://developer.apple.com/reference/scenekit/scnscene/1523577-write
