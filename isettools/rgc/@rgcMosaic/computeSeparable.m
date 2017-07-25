function [rgcL, nTrialsLinearResponse] = computeSeparable(rgcM, varargin)
% COMPUTESEPARABLE - Computes the RGC mosaic linear response
%
%   computeSparable(rgcM)
%   @rgcMosaic.computeSeparable(varargin)
%
% Computes the linear responses and spikes for each of the mosaics in a
% retina layer object.
%
% ***
%  PROGRAMMING:  We still have data management to deal with in terms of
%  multiple trials. 
% ***
%
% The linear responses for each mosaic are computed. The linear computation
% is space-time separation for each mosaic.  The spatial computation,
% however, is not a convolution because the RF of the cells within a mosaic
% can differ.
%
% Required inputs
%   rgcM:     A retina mosaic object 
%
% Optional inputs
%  bipolarTrials:  Multiple bipolar trials can be sent in using this
%                  variable.
%
% For each corresponding bp and rgc mosaic, the center and surround RF
% responses are calculated (matrix multiply). then the temporal impulse
% response for the center and surround is calculated.  This continuous
% operation produces the 'linear' RGC response shown in the window.
%
% The spikes are computed from the linear response in a separate routine.
%
% Science and references
%
%    * Why do we scale the bipolar voltage input with ieContrast?
%    * Why is the RGC impulse response set to an impulse?  I gather this is
%    because the photocurrent*bipolar equals the observed RGC impulse
%    response?
%
% rgcGLM model: The spikes are computed using the recursive influence of
% the post-spike and coupling filters between the nonlinear responses of
% other cells. These computations are carried in irComputeSpikes out using
% code from Pillow, Shlens, Paninski, Sher, Litke, Chichilnisky,
% Simoncelli, Nature, 2008, licensed for modification, which can be found
% at
%
%   http://pillowlab.princeton.edu/code_GLM.html
%
% See also: rgcGLM/rgcCompute, s_vaRGC in WL/WLVernierAcuity
%
% JRG/BW (c) Isetbio team, 2016

%% Check inputs

p = inputParser;
p.CaseSensitive = false;

validTypes = {'rgcGLM','rgcLNP'};
vFunc = @(x)(ismember(class(x),validTypes));
p.addRequired('rgcM',vFunc);

% We can use multiple bipolar trials as input
p.addParameter('bipolarScale',  50, @isnumeric);
p.addParameter('bipolarContrast',  1, @isnumeric);

% Not used now.  To be added later.
p.addParameter('bipolarTrials',  [], @(x) isnumeric(x)||iscell(x));

p.parse(rgcM,varargin{:});
bipolarScale    = p.Results.bipolarScale;
bipolarContrast = p.Results.bipolarContrast;

%% Remove the mean of the bipolar mosaic input, converts to contrast

% This is a normalization on the bipolar current.
% Let's justify or explain or something.

input = ieContrast(rgcM.input.get('response'),'maxC',bipolarContrast);

% vcNewGraphWin; ieMovie(input);

%% Set the rgc impulse response to an impulse

% When we feed a bipolar object into the inner retina, we don't need to do
% temporal convolution. We have the tCenter and tSurround properties for
% the rgcMosaic, so we set them to an impulse to remind us that the
% temporal repsonse is already computed.
rgcM.set('tCenter all', 1);
rgcM.set('tSurround all',1);

% We use a separable space-time receptive field that computes for
% space here.  We will implement temporal response later.
[respC, respS] = rgcSpaceDot(rgcM, input);
% vcNewGraphWin; ieMovie(respC);

% Store the linear response
rgcM.set('response linear', bipolarScale*(respC - respS));

end


