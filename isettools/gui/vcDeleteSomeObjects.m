function nRemaining = vcDeleteSomeObjects(objType, deleteList)
% Delete objects of objType at the deleteList positions
%
% Syntax:
%   nRemaining = vcDeleteSomeObjects(objType, [deleteList])
%
% Description:
%    The ISET object types that can be deleted by this call are:
%       SCENE, OPTICS, VCIMAGE, ISA.
%
%    If deleteList is empty or missing, a list dialog appears for the user
%    to choose the entries.  The list is populated by the object names.
%
%    The number of remaining objects of objType is returned.
%
%    The code below contains examples of function usage. To access, type
%    'edit vcDeleteSomeObjects.m' into the Command Window.
%
% Inputs:
%    objType    - String. A string describing the object type.
%    deleteList - List. List of objects to delete.
%
% Outputs:
%    nRemaining - List. The list of remaining objects.
%
% Optional key/value pairs:
%    None.
%

% History:
%    xx/xx/05       Copyright ImagEval Consultants, LLC, 2005.
%    05/09/18  jnm  Formatting

% Examples:
%{
    % ETTBSkip - Skipping a broken example.
    ('SCENE');
    sceneWindow();
    vcDeleteSomeObjects('OI');
    oiWindow();
    vcDeleteSomeObjects('SENSOR');
    sensorImageWindow();
    vcDeleteSomeObjects('VCI');
    ipWindow();

    objType = 'vci';
    deleteList = [1 2];
    nRemaining = vcDeleteSomeObjects(objType, deleteList);

    objType = 'sensor';
    vcDeleteSomeObjects(objType);
    sensorImageWindow();
%}

if notDefined('objType'), error('Object type required'); end
objType = vcEquivalentObjtype(objType);  % Translate to proper name

if notDefined('deleteList')
    % Get the list from the user using a listdlg
    obj = vcGetObjects(objType);
    nObj = length(obj);
    lst = cell(1, nObj);
    for ii = 1:nObj  % Get the object names
        lst{ii} = obj{ii}.name;
    end
    deleteList = listdlg('ListString', lst);
    if isempty(deleteList), disp('User canceled'); return; end
end

% Sort the list from highest to lowest.  This prevents renumbering the
% objects in the list as we delete. For example, if we delete 4 and 6, then
% deleting 6 first leaves 4 in the 4th position.
deleteList = sort(deleteList, 'descend');
for ii = 1:length(deleteList)
    nRemaining = vcDeleteObject(objType, deleteList(ii));
end

end