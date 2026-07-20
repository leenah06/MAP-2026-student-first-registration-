function [sol,xInit, fval,exitflag,output] = ...
    timeBlockBasedModel(semester,xInit)

%==========================================================
% LOAD DATA
%==========================================================

if nargin < 1
    semester = "FA25";
end

load(semester + "_SchedulingData.mat")

S = StudentMatrix;
F = FacultyMatrix;

[numStudents,numCourses] = size(S);
numFaculty = size(F,1);
uStudents = ones(numStudents,1);


%==========================================================
% TIMETABLE GEOMETRY
%==========================================================

slotTable = buildSlotTable();

[slotTimeIncidence,timeBlockNames] = ...
    buildTimeIncidenceMatrix(slotTable);

numSlots = height(slotTable);

%----------------------------------------------------------
% CONFLICT GROUPS
%----------------------------------------------------------

conflictGroups = ...
    generateSlotConflictGroups(slotTimeIncidence);

conflictGroups = ...
    reduceConflictGroups(conflictGroups);

numConflictGroups = length(conflictGroups);

%==========================================================
% COURSE DATA
%==========================================================

classLoads = full(sum(S))';

capacity = 25;
M = capacity*ones(numCourses,1);

%==========================================================
% PREFERENCE MATRIX
%==========================================================

R = zeros(size(S));

for i = 1:numStudents

    courses = find(S(i,:));

    n = length(courses);

    if n == 0
        continue
    end

    R(i,courses) = randperm(n);
    % You only get to rank 4 courses, so having 10 courses should help you.
    % Remove higher rankings
    removeCouseIndices = find(R(i,:)>4);
    R(i,removeCouseIndices) = 0;

end

NR = R;

NR(R==1) = 2;
NR(R==2) = 4;
NR(R==3) = 6;
NR(R==4) = 7;

%==========================================================
% MODEL DATA
%==========================================================

modelData = struct;

modelData.S              = S;
modelData.F              = F;

modelData.NR             = NR;

modelData.courseData     = courseData;
modelData.slotTable      = slotTable;
modelData.slotTimeIncidence = slotTimeIncidence;

modelData.conflictGroups = conflictGroups;

modelData.classLoads     = classLoads;
modelData.capacity       = capacity;

modelData.numStudents    = numStudents;
modelData.numFaculty     = numFaculty;
modelData.numCourses     = numCourses;
modelData.numSlots       = numSlots;
modelData.numConflictGroups = numConflictGroups;

%==========================================================
% INITIAL SOLUTION
%==========================================================

if nargin < 2

    xInit = buildWarmStart(modelData);

elseif isnumeric(xInit)

    xInit = buildWarmStart(modelData,xInit);

end

%==========================================================
% REPORT
%==========================================================

fprintf('Slots            : %d\n',numSlots);
fprintf('Conflict Groups  : %d\n',numConflictGroups);
fprintf('A variables      : %d\n',numStudents*numConflictGroups);
fprintf('B variables      : %d\n',numFaculty*numConflictGroups);

%==========================================================
% OPTIMIZATION MODEL
%==========================================================

assignmentProb = optimproblem;

%==========================================================
% DECISION VARIABLES
%==========================================================

% Course assigned to slot

T = optimvar( ...
    'T', ...
    numCourses, ...
    numSlots, ...
    'Type','integer', ...
    'LowerBound',0, ...
    'UpperBound',1);

% Student conflict penalties

A = optimvar( ...
    'A', ...
    numStudents, ...
    numConflictGroups, ...
    'Type','integer', ...
    'LowerBound',0);

% Faculty conflict penalties

B = optimvar( ...
    'B', ...
    numFaculty, ...
    numConflictGroups, ...
    'Type','integer', ...
    'LowerBound',0);

% Capacity penalties
%{
P = optimvar( ...
    'P', ...
    numCourses, ...
    'Type','integer', ...
    'LowerBound',0);
%}
% Preference penalties

psi = optimvar( ...
    'psi', ...
    numStudents, ...
    numConflictGroups, ...
    'Type','integer', ...
    'LowerBound',0);

%==========================================================
% ASSIGNMENT CONSTRAINT
%==========================================================

assignmentProb.Constraints.courseAssigned = ...
    sum(T,2) == 1;

%==========================================================
% CAPACITY PENALTY
%==========================================================
%{
assignmentProb.Constraints.capacity = ...
    classLoads - P <= M;
%}
%==========================================================
% STUDENT CONFLICT CONSTRAINTS
%==========================================================

assignmentProb = ...
    addStudentConflictConstraints( ...
        assignmentProb,...
        S,...
        T,...
        A,...
        conflictGroups);

%==========================================================
% FACULTY CONFLICT CONSTRAINTS
%==========================================================

assignmentProb = ...
    addFacultyConflictConstraints( ...
        assignmentProb,...
        F,...
        T,...
        B,...
        conflictGroups);

%==========================================================
% PREFERENCE CONSTRAINTS
%==========================================================

assignmentProb = ...
    addStudentPreferenceConstraints( ...
        assignmentProb,...
        NR,...
        T,...
        psi,...
        conflictGroups);

%==========================================================
% TIME OF DAY CONSTRAINTS
%==========================================================

assignmentProb = ...
    addTimeOfDayConstraints( ...
    assignmentProb,...
    T,...
    courseData,...
    slotTable);

%==========================================================
% OBJECTIVE
%==========================================================

assignmentProb.ObjectiveSense = 'minimize';

assignmentProb.Objective = ...
    sum(A,'all') ...
    + 25*sum(B,'all') ...
    + sum(psi,'all');

%==========================================================
% SOLVE
%==========================================================

opts = optimoptions('intlinprog', ...
    'MaxTime',150);

if isempty(xInit)

    [sol,fval,exitflag,output] = ...
        solve(assignmentProb,'Options',opts);

else

    [sol,fval,exitflag,output] = ...
        solve(assignmentProb,xInit,'Options',opts);

end


Tsol = round(sol.T);

disp('T=')
disp(Tsol);