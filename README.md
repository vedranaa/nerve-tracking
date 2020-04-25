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
  - (b) Change the active setting for a boundary. Toggles between three options: *any*, *bright inside*, and *dark inside*.
  - (s) Save nerves in a .mat file named *NERVES_XY*. Overwrites previously saved nerves.
  
## The suggested workflow

Start by getting an overview of the data by navigating through all slices. To add a nerve, navigate to the first slice, then add the curve, fit, and propagate. Navigate through slices to validate the fit. If needed, edit the curve in a slice and propagate. Remember that propagate changes all subsequent slices, so make all edits in order -- starting with the first slice, ending with the last slice. If the fit is not satisfactory in some slice e.g. *z*, use copy to duplicate the result from an earlier slice e.g. *z-1*. You may or may not edit the curve in slice *z*. Then chose a later slice e.g. *z+1* to initiate propagation. Remember to get back to the first slice in order to add another nerve.    

## Example data

Example data for running the gui, and the example scrips, will be made available. In the mean time, to try the gui you can use `mri` data available in MATLAB. Note that this is far from optimal data for gui, since all background is masked to be fully black (0) and structures are not tubular. Still, you can get a reasonable segmentation of the head. 

```matlab
%% a test with matlabs build-in data
load mri
nerve_tracking_gui(squeeze(D(:,:,1,:)))
```
