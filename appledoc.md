
Library
-------

AssimpKit
=========

Create 3D SceneKit scenes from files imported by assimp library with support for
skeletal animations.

---

Overview
========

AssimpKit currently supports ***30 file formats*** that allows you to use these
files directly in SceneKit without having to convert these to any of the files
that SceneKit or Model IO supports thereby saving an extra step in your asset
pipeline.

You can use the AssimpKit API to easily load, view and inspect such files with
just few lines of code, including skeletal animations.

Getting Started with AssimpKit
------------------------------

Table I-1 lists the important classes in AssimpKit.

***Table I-1*** Important classes in AssimpKit.

Class/Category        | Description         
----------------------| ----------------- 
SCNScene(AssimpImport)| The container for all SceneKit content, loaded with assimp.
SCNNode(AssimpImport) | The node category to add animation to a node.

You can use the AssimpImport category defined on SCNScene to load scenes. The
post processing steps that the assimp library can apply to the imported data are
listed at AssimpKitPostProcessSteps.

The imported SCNAssimpScene contains a model SCNScene which represents the 3D
model and the skeleton if it contains one, in addition to the array of
animations each represented by an SCNScene object. The SCNAssimpScene also
contains the key names for the animations which can be used when adding,
removing animations.

You can load a scene which is a part of your app bundle, as in Listing I-1
below.

***Listing I-1*** Load a scene which is part of your app bundle

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
                    
You can load a scene by specifying a file URL, as in Listing I-2 below.

***Listing I-2*** Load a scene with a file URL

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

Skeletal Animations
-------------------

AssimpKit builds on top of the skeletal animation support provided by SceneKit.
For any scene that contains skeletal animation data, it creates a skinner and
sets it to the node whose geometry the skinner deforms. The animated scene after
importing will contain a set of animations each with a unique animation key. You
only have to add the animation to the scene to play it.

AssimpKit supports skeletal animations irrespective of whether they are defined
in one animation file or multiple animation files.

AssimpKit supports CAMediaTiming, animation attributes and animating scene kit
content with an SCNAssimpAnimSettings class which you can (optionally) pass when
adding an animation. You can set animation events and a delegate as well.

You can load an animation which is defined in the same file as the model you are
animating, using the listing I-3 below.

***Listing I-3*** Load and play an animation which is defined in the same file

    #import <AssimpKit/PostProcessing.h>
    #import <AssimpKit/SCNScene+AssimpImport.h>
    #import <AssimpKit/SCNAssimpAnimSettings.h>

    // The path to the file path must not be a relative path
    NSString *boyPath = @"/of/assets/astroBoy_walk.dae";

    // Start the import on the given file with some example postprocessing
    // Usually - if speed is not the most important aspect for you - you'll
    // probably request more postprocessing than we do in this example.
    SCNAssimpScene *scene = 
        [SCNScene assimpSceneWithURL:[NSURL URLWithString:boyPath];
                    postProcessFlags:AssimpKit_Process_FlipUVs |
                                     AssimpKit_Process_Triangulate]];

    // add the walk animation to the boy model scene
    // add an animation event as well as a delegate
    SCNAssimpAnimSettings *settings =
              [[SCNAssimpAnimSettings alloc] init];
    settings.repeatCount = 3;

    NSString *key = [scene.animationKeys objectAtIndex:0];
    SCNAnimationEventBlock eventBlock =
        ^(CAAnimation *animation, id animatedObject,
          BOOL playingBackward) {
            NSLog(@" Animation Event triggered ");
            // You can remove the animation
            // [scene.rootNode removeAnimationSceneForKey:key];
        };
    SCNAnimationEvent *animEvent =
        [SCNAnimationEvent animationEventWithKeyTime:0.9f
                                               block:eventBlock];
    NSArray *animEvents =
        [[NSArray alloc] initWithObjects:animEvent, nil];
    settings.animationEvents = animEvents;

    settings.delegate = self;

    // get the animation which is defined in the same file
    SCNScene *animation = [animScene animationSceneForKey:key];
    [scene.modelScene.rootNode addAnimationScene:animation
                                          forKey:key
                                    withSettings:settings];

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the model scene to the view
    scnView.scene = scene.modelScene;

You can load an animation which is defined in a separate file from the model you
are animating, using the listing I-5 below.

***Listing I-4*** Load and play an animation which is defined in a separate file

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
    // use the default settings, for custom settings see previous listing I-4
    [scene.modelScene.rootNode addAnimation:jumpStartAnim
                                     forKey:jumpId
                               withSettings:nil];

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the model scene to the view
    scnView.scene = scene.modelScene;

Managing Animations
-------------------

The SCNNode+AssimpImport category simulates the SCNAnimatable protocol and
provides methods to attach, remove, pause and resume animations.

Serialization and integrating with asset pipeline
-------------------------------------------------

You can serialize the model and animation scenes in SCNAssimpScene using the [write(to:options:delegate:progressHandler:)](https://developer.apple.com/reference/scenekit/scnscene/1523577-write) defined in `SCNScene` to export to either `.scn` or `.dae` file. See the discussion section of [write(to:options:delegate:progressHandler:)](https://developer.apple.com/reference/scenekit/scnscene/1523577-write) for more details.

By exporting using the above serialization method, you can both edit the exported assets in XCode's scene editor and also integrate the assets imported into your application's asset pipeline. 


File formats supported by AssimpKit
-----------------------------------

Currently AssimpKit supports the following file formats:

***3d, 3ds, ac, b3d, bvh, cob, dae, dxf, ifc, irr, md2, md5mesh, md5anim,
m3sd, nff, obj, off, mesh.xml, ply, q3o, q3s, raw, smd, stl, wrl, xgl, zgl, fbx,
md3***