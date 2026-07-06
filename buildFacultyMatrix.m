function [F,numFaculty] = buildFacultyMatrix(courseDataFiltered, uniqueFaculty, uniqueTrueIDs)
% BUILDFACULTYMATRIX Construct the faculty-course matrix.
%
% Inputs:
%   courseDataFiltered - course scheduling table
%   uniqueFaculty      - vector of unique faculty IDs
%   uniqueTrueIDs      - vector of unique course IDs
%
% Output:
%   F(i,j) = 1 if faculty i teaches course j

numFaculty = length(uniqueFaculty);
numCourses = length(uniqueTrueIDs);

F = zeros(numFaculty,numCourses);

% Match faculty IDs to row indices
[~,facultyIdx] = ismember(courseDataFiltered.facultyID,uniqueFaculty);

% Match course IDs to column indices
[~,courseIdx] = ismember(courseDataFiltered.trueRegID,uniqueTrueIDs);

for k = 1:height(courseDataFiltered)

    if facultyIdx(k)>0 && courseIdx(k)>0
        F(facultyIdx(k),courseIdx(k)) = 1;
    end

end

end

%[appendix]{"version":"1.0"}
%---
