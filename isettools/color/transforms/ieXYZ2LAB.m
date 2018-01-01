function lab = ieXYZ2LAB(xyz, whitepoint, useOldCode)
% Convert CIE XYZ values to CIE LAB values
%
% Syntax:
%   lab = ieXYZ2LAB(xyz, whitepoint, useOldCode)
%
% Description:
%    The CIELAB values are used for color metric calculations in the
%    engineering and psychology communities.  Let us know if you
%    would like to have the deltaE2000. The formula for XYZ to CIELAB
%    requires specifying the XYZ values of the white point.
%
%    The Matlab image toolbox routines makecform and applycform are
%    the default CIELAB transforms. The Matlab implementation converts
%    CIE 1931 XYZ to CIE 1976 L*a*b*. 
%
%    We include, as an option, the version we implemented prior to
%    Matlab's addition of this functionality.
%
% Inputs:
%    xyz        - Can be in either XW or RGB format.
%    whitePoint - A 3-vector of the xyz values of the white point.
%    useOldCode - A boolean indicating whether or not to use old code.
%
% Outputs:
%    lab        - CIE Lab values are returned in the same format
%                 (RGB or XW) as the input XYZ. 
%
% References:
%    Read about CIELAB formulae in Wyszecki and Stiles, page 167 and other
%    standard texts.
%
%    For a (very small) problem with the official formula, see
%    <http://www.brucelindbloom.com/index.html?LContinuity.html>
%
% Notes:
%    * TODO: Must specify if XYZ is 2 deg or 10 deg XYZ? CIELAB probably
%      requires one of them. I think XYZ 10. Must check. Or do we just
%      specify in the methods - BW ). 
%
% Copyright ImagEval Consultants, LLC, 2003.
%
% See Also:
%    ieLAB2XYZ

% History
%    08/18/15  dhb  Change conditional on exist of makecform, works for
%                   p-code too.
%    10/25/17  jnm  Comments & formatting
%    11/13/17  baw  Updated comments to match behavior on use of old
%                   code
%    11/17/17  jnm  Formatting
%    12/21/17  baw  Sent reference to ieLAB2XYZ


% Examples:
%{
   vci = vcGetObject('vcimage');
   [locs, rgb] = macbethSelect(vci); 
   dataXYZ = imageRGB2xyz(vci, rgb);
   whiteXYZ = dataXYZ(1, :);
   lab = ieXYZ2LAB(dataXYZ, whiteXYZ);
%}

if notDefined('xyz'), error('No data.'); end
if notDefined('whitepoint'), error('Whitepoint is required'); end
if notDefined('useOldCode'), useOldCode = false; end

if (exist('makecform', 'file')) &&  ~useOldCode
    % Convert CIE 1931 XYZ to CIE 1976 L*a*b*
    % Their notes suggest using the image processing toolbox xyz2lab
    % function. 
    cform = makecform('xyz2lab', 'WhitePoint', whitepoint(:)');
    lab = applycform(xyz, cform);
else
    % Set the white point values
    if   (numel(whitepoint) ~= 3 )
        error('whitepoint must be 3x1')
    else
        Xn = whitepoint(1);
        Yn = whitepoint(2);
        Zn = whitepoint(3);
    end

    if ndims(xyz) == 3
        [r, c, ~] = size(xyz);
        lab = zeros(r * c, 3);

        x = xyz(:, :, 1) / Xn;
        x = x(:);
        y = xyz(:, :, 2) / Yn;
        y = y(:);
        z = xyz(:, :, 3) / Zn;
        z = z(:);

    elseif ismatrix(xyz)
        x = xyz(:, 1) / Xn;
        y = xyz(:, 2) / Yn;
        z = xyz(:, 3) / Zn;

        % allocate space
        lab = zeros(size(xyz));
    end

    % Find out points < 0.008856
    xx = find(x <= 0.008856);
    yy = find(y <= 0.008856);
    zz = find(z <= 0.008856);

    % compute L* values
    % fx, fy, fz represent cases <= 0.008856
    % For a good (obsessive) discussion see the URL
    % http://www.brucelindbloom.com/index.html?LContinuity.html
    fy = y(yy);
    
    % L* calculation
    y = y .^ (1/3);
    lab(:, 1)  = 116 * y - 16;
    lab(yy, 1) = 903.3 * fy;

    % a* b* calculation
    fx = 7.787 * x(xx) + 16 / 116;
    fy = 7.787 * fy + 16 / 116;
    fz = 7.787 * z(zz) + 16 / 116;
    x = x .^ (1 / 3);
    z = z .^ (1 / 3);
    x(xx) = fx;
    y(yy) = fy;
    z(zz) = fz;

    lab(:, 2) = 500 * (x - y);
    lab(:, 3) = 200 * (y - z);

    % return lab in the appropriate shape
    % Currently it is a XW format. If the input had three dimensions
    % then we need to change it to that format.
    if ndims(xyz) == 3
        lab = XW2RGBFormat(lab, r, c);
    end
end
end
