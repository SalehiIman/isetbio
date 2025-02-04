function rgcM = initSpace(rgcM,varargin)
% Initialize the spatial rf properties of a rgc mosaic for a cell type
%
%    rgcM = rgcMosaic.initSpace(varargin)
%
% Required inputs
%   rgcM:     the mosaic
%   cellType: is one of rgcM.validCellTypes (spacing and capitalization are
%             ignored).
%
% Optional inputs (Parameter-Value pairs)
%   'rfDiameter'                 % in spatial units of bipolar samples
%   'centerNoise'                % in spatial units of bipolar samples
%   'ellipseParams'              % A,B,rho
%   'centerSurroundSizeRatio'  
%   'centerSurroundAmpRatio'   
%
% Scientific notes and references
%
% RF size scale parameters: Parasol RFs are the largest, while Midget RFs
% are about half the diameter of Parasol RFs, and SBC RFs are 1.2X the
% diameter of Parasol RFs.
%
% In order to create the spatial RFs for each type of cell, we compute the
% RF size for the On Parasol cells at a particular eccentricity based on
% data from Watanabe & Rodieck (J. Comp. Neurol., 1989), Croner & Kaplan
% (Vision Research, 1995) and Chichilniksy & Kalmar (J Neurosci., 2002,
% Fig. 5, pg. 2741.).
%
% For other types of RGCs, we multiply the On Parasol RF size by a unitless
% factor as listed here. The multipliers are based on Dacey, 2004, "Retinal
% ganglion cell diversity", in The Cognitive Neurosciences, as well as
% parameter fits to mosaic data from the Chichilnisky Lab found in the
% EJLExperimentalRGC iestbio repository.
%
% See Chichilnisky, E. J., and Rachel S. Kalmar. "Functional asymmetries
% in ON and OFF ganglion cells of primate retina." The Journal of
% Neuroscience 22.7 (2002).
%
% We add notes about the Watson paper here and insert some of JRG's code
% for setting the sizes here.
%
% Old notes
%
% sRFcenter, sRFsurround matrices and cellLocation are in units of the
% inputObj - scene pixels, cones or bipolar cells.
%
% rfDiaMagnitude is in units of micrometers.
%
% tonicDrive is in units of conditional intensity.
%
%
% Example:
% See also:
%
% JRG/BW ISETBIO Team 2015

%% All three arguments are required

p = inputParser;
p.KeepUnmatched = true;

% Possible RGC models.
vFunc = @(x)(ismember(class(x),{'rgcGLM','rgcLNP'}));
p.addRequired('rgcM',vFunc);
p.addParameter('rfDiameter',[],@isscalar);         % in units of bipolar samples
p.addParameter('centerNoise',.15,@isscalar);      % in units of bipolar samples
p.addParameter('ellipseParams',[],@(x)(ismatrix(x) || isempty(x)));  % A,B,rho

% See notes in RGCRFELLIPSES
p.addParameter('centerSurroundSizeRatio',sqrt(0.75),@isscalar);
p.addParameter('centerSurroundAmpRatio', .7*0.774,@isscalar);
p.parse(rgcM,varargin{:});

rgcM.rfDiameter = p.Results.rfDiameter;

%% Set up defaults for the sizes and weights.
switch ieParamFormat(rgcM.cellType)
    case 'onparasol'
        rfSizeMult = 1;      % On Parasol RF size multiplier
    case 'offparasol'
        rfSizeMult = 0.85;   % Off Parasol RF size multiplier
    case 'onmidget'
        rfSizeMult = 0.5;    % On Midget RF size multiplier
    case 'offmidget'
        rfSizeMult = 0.425;  % Off Midget RF size multiplier
    case {'onsbc','smallbistratified'}
        rfSizeMult = 1.1;    % SBC RF size multiplier
end

% If diameter has not been set, assign its value based on the literature
if isempty(rgcM.rfDiameter)
    % If the species is macaque, we might use this
    % 
    % Calculate spatial RF diameter for ON Parasol cell at a particular TEE
    % See Chichilnisky, E. J., and Rachel S. Kalmar. "Functional asymmetries
    % in ON and OFF ganglion cells of primate retina." The Journal of
    % Neuroscience 22.7 (2002), Fig. 5, pg. 2741. 2STD fit in micrometers.
    retinalLocationToTEE = temporalEquivEcc(rgcM.parent.center);
    %
    % For human work, we should probably go with what Jon and Marissa C.
    % are doing.  Let's ask them (BW).
    
    receptiveFieldDiameterParasol2STD = ...
        receptiveFieldDiameterFromTEE(retinalLocationToTEE);
    
    % The spatial RF diameter in pixels (or cones) is therefore the diameter in
    % microns divided by the number of microns per pixel (or cone), scaled by
    % the factor determined by the type of mosaic that is being created.
    
    % in micrometers; divide by umPerScenePx to get pixels
    rgcM.rfDiameter = rfSizeMult*(receptiveFieldDiameterParasol2STD/2);
    
    % We now convert to input samples
    
end


%% Build spatial RFs of all RGCs in this mosaic.

% These are the parameters we use to build the jittered, hex spatial array
% of center positions and ellipsoid RF shapes
params.centerNoise        = p.Results.centerNoise;
params.ellipseParams      = p.Results.ellipseParams;
params.centerSurroundSizeRatio = p.Results.centerSurroundSizeRatio;
params.centerSurroundAmpRatio  = p.Results.centerSurroundAmpRatio;

rgcM.spatialArray(params);

end
