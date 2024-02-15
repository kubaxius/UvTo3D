
# UV to 3D map generator

Program that takes 3D model, and creates 2D array where indexes correspond to pixels on UV map of the model, and values correspond to points in 3D space where said pixels would be drawn.

I created it so it would be easier to generate seamless noise textures for 3D objects, and also because it would make it super easy to convert from one map projection to other.

Are there easier ways to do this? Probably. Could you write much better, more eficient and less clunky program than this? Most certainly. Do I care? Not really.
## How To Use

1. Open this project in blender.

2. Import your 3D model and input it into the scene, like this, for example:
![image](https://github.com/kubaxius/UvTo3D/blob/master/readme_images/structire.PNG?raw=true)

Remember that more complicated meshes take much more time to map.

3. Drag the mesh into "Mesh Node" field in the "Main" Node.
![image](https://github.com/kubaxius/UvTo3D/blob/master/readme_images/settings.PNG?raw=true)

4. Start program and set it up. If you want the array to generate Noise, remember that your texture does not have to be big at all. For the monkey here I would go with 256/256, or even smaller.
![image](https://github.com/kubaxius/UvTo3D/blob/master/readme_images/start.PNG?raw=true)

By the way, "sphere mode" normalizes all coordinates at the end and multiplies them by given radius, since this gives much better results. After this operation all the points lie exaclty on the sphere's surface.

5. Click Start and watch the show.
![image](https://github.com/kubaxius/UvTo3D/blob/master/readme_images/mid.PNG?raw=true)

6. After the program finishes it generates noise and puts it on the model. so you can see if any seams are visible.
![image](https://github.com/kubaxius/UvTo3D/blob/master/readme_images/fin.PNG?raw=true)

7. If you want to now import your newly generated file, just check main.gd and use one of my functions.