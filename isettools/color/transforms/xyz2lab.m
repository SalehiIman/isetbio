function lab = xyz2lab(xyz, whitepoint, useOldCode)
% [Deprecated. Use ieXYZ2LAB] Convert CIE XYZ values to CIE LAB values
%
% Syntax:
%   lab = xyz2lab(xyz, whitepoint, [useOldCode])
%
% Description:
%    Convert CIE XYZ into CIE L*a*b*. The CIELAB values are used for color
%    metric calculations, such as deltaE2000. The formula for XYZ to
%    CIELAB require knowledge of the XYZ white point as well.
%
% Inputs:
%    xyz        - Either XW or RGB format.
%    whitepoint - A 3-vector of the xyz values of the white point.
%    useOldCode - Optional variable whether or not to use matlab
%                 functions. Default value is false.
%
% Outputs:
%    CIELAB     - Values are returned in the same format (RGB or XW) as the
%                 input XYZ. 
%
% Notes:
%    - Read about CIELAB formulae in Wyszecki and Stiles, page 167 and
%      other standard texts. 
%    - The Matlab image toolbox routines makecform and applycform have
%      CIELAB transforms. These are not the default, however, because they
%      are not in all versions. Instead, we default to the code we used
%      for many years. But by setting useOldCode = 0, you get the Matlab
%      implementation. [Note: JNM - What version(s) are they (not) present
%      in? How can we use this to determine version support going forward?]
%    - TODO: Must specify if XYZ is 2 deg or 10 deg XYZ? CIELAB probably
%      requires one of them. I think XYZ 10. Must check. Or do we just
%      specify in the methods - BW ). 
%
% References:
%    For a (very small) problem with the official formula, see
%    <http://www.brucelindbloom.com/index.html?LContinuity.html>
%
% See Also:
%    lab2xyz
%

% History:
%    xx/xx/03       (c) ImagEval Consultants, LLC, 2003.
%    11/17/17  jnm  Formatting
%

% Examples:
%{
   vci = vcGetObject('vcimage');
   [locs, rgb] = macbethSelect(vci); 
   dataXYZ = imageRGB2xyz(vci, rgb);
   whiteXYZ = dataXYZ(1, :);
   lab = xyz2lab(dataXYZ, whiteXYZ);
%}

error('Deprecated. Use ieXYZ2LAB');

%{
if notDefined('xyz'), error('No data.'); end
if notDefined('whitepoint'), error('Whitepoint is required'); end
if notDefined('useOldCode'), useOldCode = false; end

if (exist('makecform', 'file') == 2) &&  ~useOldCode
    % This is where we want to be, but it only exists in the relatively
    % recent Matlab routines.
    % Matlab's implementation is only for CIELAB 1976
    cform = makecform('xyz2lab', 'WhitePoint', whitepoint(:)');
    lab = applycform(xyz, cform);
else
    % Set the white point values
    if (numel(whitepoint) ~= 3 )
        error('whitepoint must be 3x1')
    else
        Xn = whitepoint(1);
        Yn = whitepoint(2);
        Zn = whitepoint(3);
    end

    if ndims(xyz) == 3
        [r, c, ~] = size(xyz);
        lab = zeros(r*c, 3);

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
    lab(:, 1)   = 116 * y - 16;
    lab(yy, 1) = 903.3 * fy;

    % a* b* calculation
    fx = 7.787 * x(xx) + 16/116;
    fy = 7.787 * fy + 16/116;
    fz = 7.787 * z(zz) + 16/116;
    x = x .^ (1 / 3);
    z = z .^ (1 / 3);
    x(xx) = fx;
    y(yy) = fy;
    z(zz) = fz;

    lab(:, 2) = 500 * (x - y);
    lab(:, 3) = 200 * (y - z);

    % return lab in the appropriate shape
    % Currently it is a XW format. If the input had three dimensions then
    % we need to change it to that format.
    if ndims(xyz) == 3
        lab = XW2RGBFormat(lab, r, c);
    end
end

end
%}
