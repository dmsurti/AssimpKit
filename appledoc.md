
Library
-------

AssimpKit
=========

Create 3D SceneKit scenes from files imported by assimp library with support for
skeletal animations.

---

Overview
========

AssimpKit currently supports ***31 file formats*** that allows you to use these
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
SCNAssimpAnimation    | The container for all SceneKit skeletal animation content.

You can use the AssimpKit category defined on SCNScene to load scenes.

You can load a scene which is a part of your app bundle, as in Listing I-1 below.

***Listing I-1*** Load a scene which is part of your app bundle

    #import "SCNScene+AssimpImport.h"

    NSString *spider = @"spider.obj";

    SCNAssimpScene* scene = [SCNScene assimpSceneNamed:spider];

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the scene to the view
    scnView.scene = scene;
                    
You can load a scene by specifying a file URL, as in Listing I-2 below.

***Listing I-2*** Load a scene with a file URL

    #import "SCNScene+AssimpImport.h"

    // The path to the file path must not be a relative path
    NSString *soldierPath = @"/assets/apple/attack.dae";

    SCNAssimpScene *scene = 
        [SCNScene assimpSceneWithURL:[NSURL URLWithString:soldierPath]];

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the scene to the view
    scnView.scene = scene;

Skeletal Animations
-------------------

AssimpKit builds on top of the skeletal animation support provided by SceneKit.
For any scene that contains skeletal animation data, it creates a skinner and
sets it to the node whose geometry the skinner deforms. The animated scene after
importing will contain a set of animations each with a unique animation key. You
only have to add the animation to the scene to play it, without even worrying
about which node to add the animation.

AssimpKit supports skeletal animations irrespective of whether they are defined
in one animation file or multiple animation files.

You can load an animation which is defined in the same file as the model you are
animating, using the listing I-3 below.

***Listing I-3*** Load and play an animation which is defined in the same file

    #import "SCNScene+AssimpImport.h"

    // The path to the file path must not be a relative path
    NSString *boyPath = @"/of/assets/astroBoy_walk.dae";

    SCNAssimpScene *scene = 
        [SCNScene assimpSceneWithURL:[NSURL URLWithString:boyPath]];

    // get the animation which is defined in the same file
    NSString *walkID = @"astroBoy_walk-1";
    SCNAssimpAnimation *walkAnim = [scene animationForKey:walkAnim];

    // add the walk animation to the boy scene
    [scene addAnimation:attackAnim];

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the scene to the view
    scnView.scene = scene;

You can load an animation which is defined in a separate file from the model you
are animating, using the listing I-5 below.

***Listing I-4*** Load and play an animation which is defined in a separate file

    NSString *explorer = @"/assets/apple/explorer_skinned.dae";
    SCNAssimpScene *scene =
        [SCNScene assimpSceneWithURL:[NSURL URLWithString:explorer]];

    // load an animation which is defined in a separate file
    NSString *jumpAnim = @"/explorer/jump_start.dae"];
    SCNAssimpScene *jumpStartScene = [assimpImporter importScene:jumpAnim];

    // get the aniamtion with animation key
    NSString *jumpId = @"jump_start-1";
    SCNAssimpAnimation *jumpStartAnim = [jumpStartScene animationForKey:jumpId];

    // add the jump animation to the explorer scene
    [scene addAnimation:jumpStartAnim];

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the scene to the view
    scnView.scene = scene;

File formats supported by AssimpKit
-----------------------------------

Currently AssimpKit supports the following file formats:

***3d, 3ds, ac, b3d, bvh, cob, dae, dxf, hmp, ifc, irr, md2, md5mesh, md5anim, mdl,
m3sd, nff, obj, off, mesh.xml, ply, q3o, q3s, raw, smd, stl, wrl, xgl, zgl, fbx,
md3***