function displayInfo(obj, varargin)
% Print various infos about the cone mosaic
%
% Syntax:
%    displayInfo(obj)
%
% Description:
%    Print various infos about the cone mosaic
%
% Inputs:
%    obj - The cone mosaic hex object
%
% Outputs:
%    None.
%
% Optional key/value pairs:
%    plotApertureStats         - Boolean, whether the plot a histogram of
%                                aperture diameter and light collecting area

% History:
%    xx/xx/15  NPC  ISETBIO TEAM, 2015
%    02/16/18  jnm  Formatting
%    10/12/18  NPC  Now reporting & plotting stats for inner segment aperture and area

% parse input
p = inputParser;
p.addParameter('plotApertureStats', false, @islogical);
p.parse(varargin{:});


%[apertureCoverage, geometricCoverage] = obj.retinalCoverage();
apertureStats = computeApertureStats(obj, p.Results.plotApertureStats);

fprintf('\nMosaic info:\n');
fprintf('%53s %2.1f (w) x %2.1f (h)\n', 'Size (microns):', ...
    obj.width * 1e6, obj.height * 1e6);
fprintf('%53s %2.2f (w) x %2.2f (h)\n', 'FOV (deg):', ...
    obj.fov(1), obj.fov(2));
fprintf('%53s %2.3f (aperture) x %2.3f (geometric)\n', ...
    'Retinal coverages:', obj.innerSegmentCoverage, obj.coverage);
fprintf('%53s %0.0f\n', 'Grid resampling factor:', obj.resamplingFactor);

% fprintf('%53s %2.2f (w) x %2.2f (h)\n', ...
%     'Cone geometric aperture (microns):', ...
%     obj.pigment.width * 1e6, obj.pigment.height * 1e6);
% fprintf('%53s %2.2f (w) x %2.2f (h)\n', ...
%     'Cone light colleting aperture (microns):', ...
%     obj.pigment.pdWidth * 1e6, obj.pigment.pdHeight * 1e6);

fprintf('%53s Min=%2.4f, Mean=%2.4f, Median=%2.4f, Max=%2.4f \n', 'Inner segment diameter (microns): ', ...
    apertureStats.rangeDiameterMicrons(1), apertureStats.meanDiameterMicrons, apertureStats.medianDiameterMicrons, apertureStats.rangeDiameterMicrons(2));
fprintf('%53s Min=%2.4f, Mean=%2.4f, Median=%2.4f, Max=%2.4f \n', 'Inner segment area (microns^2): ', ...
    apertureStats.rangeLightCollectingArea(1), apertureStats.meanLightCollectingArea, apertureStats.medianLightCollectingArea, apertureStats.rangeLightCollectingArea(2));


fprintf('%53s %2.4f \n', 'Cone geometric area (microns^2):', ...
    obj.pigment.area * 1e12);
fprintf('%53s %2.4f\n', 'Cone light colleting area (microns^2):', ...
    obj.pigment.pdArea * 1e12);
%fprintf('%53s %2.3f \n', 'Cone coverage :', obj.coverage);
%fprintf('%53s %2.3f \n', 'Cone coverage (inner segments):', obj.innerSegmentCoverage);
fprintf('%53s %2.0f cols x %2.0f rows\n', 'Rectangular grid:', ...
    size(obj.patternOriginatingRectGrid, 2), ...
    size(obj.patternOriginatingRectGrid, 1));
fprintf('%53s %2.0f cols x %2.0f rows\n', 'Resampled grid:', ...
    obj.cols, obj.rows);
fprintf('%53s %d\n', 'Total cones:', numel(obj.pattern));
totalConesNum = numel(find(obj.pattern > 1));
LconesNum = numel(find(obj.pattern == 2));
MconesNum = numel(find(obj.pattern == 3));
SconesNum = numel(find(obj.pattern == 4));
fprintf('%53s %d\n', 'Active cones:' , totalConesNum);
fprintf('%53s %d (%2.3f%%)\n', 'L- cones:' , LconesNum, LconesNum/totalConesNum);
fprintf('%53s %d (%2.3f%%)\n', 'M- cones:' , MconesNum, MconesNum/totalConesNum);
fprintf('%53s %d (%2.3f%%)\n', 'S- cones:' , SconesNum, SconesNum/totalConesNum);
fprintf('%53s %2.1f cones/mm^2\n', 'Cone density (all cones):', ...
    numel(obj.pattern) / (obj.width * obj.height * 1e6));
fprintf('%53s %2.1f cones/mm^2\n', 'Cone density (active cones):', ...
    numel(find(obj.pattern > 1)) / (obj.width * obj.height * 1e6));
fprintf('%53s %d\n\n', 'Ecc-based efficiency:', obj.eccBasedConeQuantalEfficiency);
end

function apertureStats = computeApertureStats(obj, plotApertureStats)
    coneIndices = find(obj.pattern > 1);
    coneXYEccentricities = obj.coneLocs(coneIndices,:) / obj.resamplingFactor;
    coneEccentricitiesInMeters = (sqrt(sum(coneXYEccentricities.^2,2)))';
    coneAnglesInDegrees = atan2(squeeze(coneXYEccentricities(:,2)), squeeze(coneXYEccentricities(:,1))) / pi * 180;
        
    [~, apertureMeters, ~] = coneSizeReadData(...
            'eccentricity',coneEccentricitiesInMeters,...
            'angle',coneAnglesInDegrees);
        
    apertureDiameterMicrons = diameterForCircularApertureFromWidthForSquareAperture(apertureMeters * 1e6);
    apertureCollectingArea = pi*(apertureDiameterMicrons/2).^2;
    apertureStats.medianDiameterMicrons = median(apertureDiameterMicrons);
    apertureStats.meanDiameterMicrons  = mean(apertureDiameterMicrons);
    apertureStats.rangeDiameterMicrons  =[min(apertureDiameterMicrons) max(apertureDiameterMicrons)];
    apertureStats.medianLightCollectingArea = pi*(apertureStats.medianDiameterMicrons/2)^2;
    apertureStats.meanLightCollectingArea = pi*(apertureStats.meanDiameterMicrons/2)^2;
    apertureStats.rangeLightCollectingArea = pi*(apertureStats.rangeDiameterMicrons/2).^2;
    
    if (plotApertureStats)
        hFig = figure();
        set(hFig, 'Position', [10 10 1000 440], 'Color', [1 1 1]);
    
        nBins = 15;
        subplot(1,2,1)
        histogram(apertureDiameterMicrons,nBins);
        axis 'square'
        xlabel('aperture diameter (\mum)');
        ylabel('number of cones'); 
        set(gca, 'FontSize', 16);
    
        subplot(1,2,2)
        histogram(apertureCollectingArea, nBins);
        axis 'square'
        xlabel('Light collecting area (\mum^2)');
        ylabel('number of cones');
        set(gca, 'FontSize', 16);
    end

end
