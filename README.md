# NerveTracking
 
Nerve tracking GUI is used for tracking nerves in volumetric data. The method is the same as used in the paper *Three-dimensional architecture of human diabetic peripheral nerves revealed by X-ray phase contrast holographic nanotomography* by Dahlin *et al.*, Scientific Reports 2020.

Nerve tracking GUI is guided trough keyboard and mouse input. Hints on the basic functionality are written, or appear, above and below the images. The most important functionality is accessed via keyboard inputs in the overview window. This is supplemented by drawing by dragging in the drawing window, see the the screenshot below. The results are visualized in the 3D visualization window, and can be exported and saved as .obj files.

<img src="/images/peripheral_nerve_screenshot.png" width="700">

The basic use of the code is: `nerve_tracking_gui(data)`. The format of `data`, and  optional inputs are explained in the help text in the code.

Keyboard input, navigation:
  - (Arrow up) One slice up.		
  - (Arrow down) One slice down.
  - (Arrow right) 10 slices up.
  - (Arrow left) 10 slices down.
  - (Page up) 50 slices up.
  - (Page down) 50 slices down.
  - (Home) To the first slice.
  - (End) To the last slice.
  
 Keyboard input, functionality:
  - (a) Add a new nerve by placing a circle. A nerve is added to all slices. The added nerve will become the active nerve.
		- (n) Change the active nerve to another already existing nerve. 
		- (e) Edit the active nerve in the current slice by dragging the curve.
		- (D, shif+d) Delete the active nerve in all slices. Cannot be undone.
		- (f) Fit the active nerve in the current slice to the image data. This function uses the active setting for boundary. 
		- (c) Copy the active nerve from the current slice to all subsequent slices. 
		- (p) Propagate the active nerve from the current slice to all subsequent slices. The nerve will be copied and fitted slice-by-slice. The current slice will not be affected. This function uses the active setting for edge boundary. 
		- (b) Change the active setting for a boundary. Toggles between three options: *any*, *bright inside*, and *dark inside'.
		- (s) Save nerves in a .mat file named *NERVES_XY*. Overwrites previously saved nerves.
