function rgcM = rgcInitSpace(rgcM,innerRetina,cellType)
% Initialize the spatial rf properties of a rgc mosaic given a cell type
%
% RF size scale parameters: Parasol RFs are the largest, while Midget RFs
% are about half the diameter of Parasol RFs, and SBC RFs are 1.2X the
% diameter of Parasol RFs.
%
% See Chichilnisky, E. J., and Rachel S. Kalmar. "Functional asymmetries
% in ON and OFF ganglion cells of primate retina." The Journal of
% Neuroscience 22.7 (2002).
%
% Implemented for these cell types
%
% [ON Parasol; OFF Parasol; ON Midget; OFF Midget; Small bistratified];
%
% JRG, ISETBIO Team, 2016


%% Set up defaults for the sizes and weights.

% More comments on these numbers
% What are the units? References.  What do these numbers refer to?
rfSizeMult = [1 .85*1 0.5 .85*0.5 1.2]; 

% Calculate spatial RF diameter for ON Parasol cell at a particular TEE
% See Chichilnisky, E. J., and Rachel S. Kalmar. "Functional asymmetries
% in ON and OFF ganglion cells of primate retina." The Journal of
% Neuroscience 22.7 (2002), Fig. 5, pg. 2741. ** What are the units? **
receptiveFieldDiameterParasol2STD = receptiveFieldDiameterFromTEE(innerRetina.temporalEquivEcc);

% If os is osIdentity, determine number of pixels per spatial RF diameter.
% If os is osLinear or osBioPhys, determine the number of cones per spatial
% RF diameter.
patchSizeX = innerRetina.spacing;
sensorRows = innerRetina.row;

% Needs to be a proper get from the inner retina
umPerSensorPx = patchSizeX/sensorRows;

% The spatial RF diameter in pixels (or cones) is therefore the diameter in
% microns divided by the number of microns per pixel (or cone), scaled by
% the factor determined by the type of mosaic that is being created.

% in microns; divide by umPerScenePx to get pixels
rgcM.rfDiameter = rfSizeMult(cellType)*(receptiveFieldDiameterParasol2STD/2); 

% Build spatial RFs of all RGCs in this mosaic - Specify units here!
[rgcM.sRFcenter, rgcM.sRFsurround, rgcM.rfDiaMagnitude, rgcM.cellLocation, rgcM.tonicDrive] = ...
    buildSpatialRFArray(innerRetina.spacing, innerRetina.row, innerRetina.col, rgcM.rfDiameter);



end
