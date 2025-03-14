# COLOUR PALETTIZER for GODOT

![spingifsm](https://github.com/user-attachments/assets/74e5f3ea-617c-4b4d-ad04-cd0abab8d7de)

A small godot posteffect that fixes the colour palette.  Other approaches I've seen do pretty heavy-duty shaders iterating over palettes, but this one generates a 3d texture in advance and just uses that as a lookup.

## How to use

![image](https://github.com/user-attachments/assets/0180a8de-c9fd-459a-bb78-128d9bbce464)

Look at the demo scene - the core is just the CanvasLayer and the Color Rect. Load an image int 'pattern source', and the script will generate the texture 3D and apply it to the postprocessmaterial on the colorrect (only at runtime right now - this can be a bit slow so ideally it would be nice to be able to save it...it shouldn't be hard to do).

You can supply anything as a palette - I use screenshots of palletes from aseprite:

![image](https://github.com/user-attachments/assets/91f48b3e-7180-460f-b641-1846452350bc)

You can also use screenshots of anything - my suggestion though is to downscale/blur the image in your favourite image editor, and then to reduce the colour palette of the image down to 64/128 colors - otherwise the search process can be *very* slow.

![image](https://github.com/user-attachments/assets/08f19248-a0c4-4b9f-bb4b-a6f2dab81695)
