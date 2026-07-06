function [S,numStudents,numCourses] = buildStudentMatrix(studentData, uniqueStudents, uniqueTrueIDs)
%BUILDSTUDENTMATRIX Construct the binary student-course matrix.
%
% Inputs:
%   studentData     - registration table
%   uniqueStudents  - vector of unique student IDs
%   uniqueTrueIDs   - vector of unique course IDs
%
% Output:
%   S(i,j)=1 if student i is registered for course j

numStudents = length(uniqueStudents);
numCourses  = length(uniqueTrueIDs);

S = zeros(numStudents,numCourses);

[~,studentIdx] = ismember(studentData.studentIDs,uniqueStudents);
[~,courseIdx]  = ismember(studentData.trueRegID,uniqueTrueIDs);

for k = 1:height(studentData)

    if studentIdx(k)>0 && courseIdx(k)>0
        S(studentIdx(k),courseIdx(k)) = 1;
    end

end

end

%[appendix]{"version":"1.0"}
%---
