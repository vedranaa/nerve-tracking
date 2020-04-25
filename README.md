# NerveTracking
 
Nerve tracking GUI is used for tracking nerves in volumetric data. The method is the same as used in the paper *Three-dimensional architecture of human diabetic peripheral nerves revealed by X-ray phase contrast holographic nanotomography* by Dahlin *et al.*, Scientific Reports 2020.

Nerve tracking GUI is guided trough keyboard and mouse input. Hints on the basic functionality are written, or appear, above and below the images. The most important functionality is accessed via keyboard inputs in the overview window. This is supplemented by drawing by dragging in the drawing window, see the the screenshot below. The results are visualized in the 3D visualization window, and can be exported and saved as .obj files.

<img src="/images/peripheral_nerve_screenshot.png" width="700">

The basic use of the code is: `nerve_tracking_gui(data)`. The format of `data`, and  optional inputs are explained in the help text in the code.

Keyboard input
 - Navigation:
  - (Arrow up) One slice up.		
  - (Arrow down) One slice down.
  - (Arrow right) 10 slices up.
  - (Arrow left) 10 slices down.
  - (Page up) 50 slices up.
  - (Page down) 50 slices down.
  - (Home) To the first slice.
  - (End) To the last slice.
