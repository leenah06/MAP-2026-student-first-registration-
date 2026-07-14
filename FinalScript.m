clear; clc;

load("FA25_SchedulingData.mat")

% Keep only N students
studentDataN = studentData(studentData.seatStatus=="N",:);

% Keep the original course list
uniqueStudentsN = unique(studentDataN.studentIDs);

[S,numStudents,numCourses] = buildStudentMatrix(studentDataN, uniqueStudentsN, uniqueTrueIDs);

[F,numFaculty] = buildFacultyMatrix(courseDataFiltered, uniqueFaculty, uniqueTrueIDs);

disp('S=')
disp(S)

size(S)

disp('F=')
disp(F)


coursePattern = extractMeetingPatterns(courseDataFiltered,uniqueTrueIDs);

fprintf("\nMeeting Pattern Summary\n")

tabulate(categorical(coursePattern))


slotTable = buildSlotTable();

Conflict = buildConflictMatrix(slotTable);

checkConflictMatrix(slotTable,Conflict);


disp(slotTable)
disp(Conflict)

fprintf("Number of conflicting slot pairs = %d\n", nnz(triu(Conflict,1)));


%% Optimization Model
assignmentProb = optimproblem;

% CONSTANTS
capacity = 25;
numTimeSlots = height(slotTable);

uStudents = ones(numStudents,1);
uFaculty  = ones(numFaculty,1);

M = capacity*ones(numCourses,1);
classLoads = sum(S)';

% VARIABLES
P = optimvar('P',numCourses,1,'Type','integer','LowerBound',0);

A = optimvar('A',numStudents,numTimeSlots,'Type','integer','LowerBound',0);

B = optimvar('B',numFaculty,numTimeSlots,'Type','integer','LowerBound',0);

psi = optimvar('psi',numStudents,numTimeSlots,'Type','integer','LowerBound',0);

T = optimvar('T',numCourses,numTimeSlots,'Type','integer','LowerBound',0,'UpperBound',1);

%% Build ranking matrix R from S
% 0 = not enrolled
% 1 = least preferred
% 4 = most preferred

R = zeros(size(S));

%rng('shuffle')

for i = 1:numStudents

    courses = find(S(i,:));

    n = length(courses);

    if n == 0
        continue;
    end

    % Randomly assign ranks 1,...,n
    R(i,courses) = randperm(n);

end

disp('R=')
disp(R)

NR = R;
NR(R==1) = 2;
NR(R==2) = 4;
NR(R==3) = 6;
NR(R==4) = 7;
disp('NR =')
disp(NR)

% indicator vectors
is50MWF  = (coursePattern=="50MWF");
is50MTWF = (coursePattern=="50MTWF");
is50MTWRF = (coursePattern=="50MTWRF");

is80MW   = (coursePattern=="80MW");
is80MWF  = (coursePattern=="80MWF");

is110MW  = (coursePattern=="110MW");
is110MWF = (coursePattern=="110MWF");

is170MW  = (coursePattern=="170MW");
is170M   = (coursePattern=="170M");
is170W   = (coursePattern=="170W");
is170F   = (coursePattern=="170F");

is80TR   = (coursePattern=="80TTH");
is110TR  = (coursePattern=="110TTH");
is170TR  = (coursePattern=="170TTH");
is170T   = (coursePattern=="170T");
is170R   = (coursePattern=="170R");

is110T  = (coursePattern=="110T");
is110WF = (coursePattern=="110WF");
is170WF = (coursePattern=="170WF");


% CONSTRAINTS
% every class assigned exactly one slot

assignmentProb.Constraints.timeslot = sum(T,2) == ones(numCourses,1);

% capacity

assignmentProb.Constraints.capacity = classLoads - P <= M;

% student conflicts

%{
for s = 1:numTimeSlots

    assignmentProb.Constraints.(sprintf('student%d',s)) = S*T(:,s) - A(:,s) <= uStudents ;

end
%}


k = 1;

%for s = 1:numTimeSlots
for i = 1:numTimeSlots-1

    for j = i+1:numTimeSlots

        if Conflict(i,j)

            assignmentProb.Constraints.(sprintf("studentConflict%d",k)) = ...
                S*T(:,i) + S*T(:,j) - A(:,i) - A(:,j) <= ones(numStudents,1);

            k = k + 1;

        end

    end

end


% faculty conflicts

%{
for s = 1:numTimeSlots

    assignmentProb.Constraints.(sprintf('faculty%d',s)) = F*T(:,s) - B(:,s) <= uFaculty;

end

%}


k = 1;

%for s = 1:numTimeSlots
for i = 1:numTimeSlots-1

    for j = i+1:numTimeSlots

        if Conflict(i,j)

            assignmentProb.Constraints.(sprintf("facultyConflict%d",k)) = ...
                F*T(:,i) + F*T(:,j) - B(:,i) - B(:,j) <= ones(numFaculty,1);

            k = k + 1;

        end

    end

end


% preference penalties

for s = 1:numTimeSlots

    assignmentProb.Constraints.(sprintf('preference%d',s)) = NR*T(:,s) <= 7*uStudents + psi(:,s);

end

% meeting pattern constraints (e.g. every MWF 50-minute course must choose one of these seven slots)


assignmentProb.Constraints.MWF50 = ...
    T(:,[1 2 3 6 7 10 11])*ones(7,1) == is50MWF;


assignmentProb.Constraints.MTWF50 = ...
    T(:,[4 8])*ones(2,1) == is50MTWF;

%{
assignmentProb.Constraints.MTWRF50 = ...
    T(:,[5 9])*ones(2,1) == is50MTWRF;

assignmentProb.Constraints.MW80 = ...
    T(:,[12 14 16 18 20 22])*ones(6,1) == is80MW;

assignmentProb.Constraints.MWF80 = ...
    T(:,[13 15 17 19 21])*ones(5,1) == is80MWF;

assignmentProb.Constraints.MW110 = ...
    T(:,[23 25 27 29])*ones(4,1) == is110MW;

assignmentProb.Constraints.MWF110 = ...
    T(:,[24 26 28])*ones(3,1) == is110MWF;

assignmentProb.Constraints.MW170 = ...
    T(:,[30 34 38])*ones(3,1) == is170MW;

assignmentProb.Constraints.M170 = ...
    T(:,[31 35 39])*ones(3,1) == is170M;

assignmentProb.Constraints.W170 = ...
    T(:,[32 36 40])*ones(3,1) == is170W;

assignmentProb.Constraints.F170 = ...
    T(:,[33 37])*ones(2,1) == is170F;

assignmentProb.Constraints.TR80 = ...
    T(:,[41 42 43 44 45])*ones(5,1) == is80TR;

assignmentProb.Constraints.TR110 = ...
    T(:,[46 47 48])*ones(3,1) == is110TR;

assignmentProb.Constraints.TR170 = ...
    T(:,[49 52 55])*ones(3,1) == is170TR;

assignmentProb.Constraints.T170 = ...
    T(:,[50 53 56])*ones(3,1) == is170T;

assignmentProb.Constraints.R170 = ...
    T(:,[51 54 57])*ones(3,1) == is170R;

%}


% OBJECTIVE

assignmentProb.ObjectiveSense = 'minimize';

assignmentProb.Objective = 1*sum(P) + 1*sum(A,'all') + 1*sum(B,'all') + 1*sum(psi,'all');


%% Solve

opts = optimoptions('intlinprog');

[sol,fval,exitflag,output] = solve(assignmentProb,'Options',opts);

disp(exitflag)
disp(fval)


Tsol = round(sol.T);

disp(Tsol)



%Create ST: shows the schedule for each student
ST = [];
for t = 1 : numTimeSlots
    tclasses = funcs.getColsInP(R,round(sol. T(:,t)),numStudents);
    ST(:,t)=funcs.getStudentTimeSlot(tclasses,0);
end

%Find the time slot given by the initial solution
multSecOgTimes = [];
for c = 1 : numCourses
    [~, ogTimeSlot] = find(round(sol.T(c,:)) == 1);
    multSecOgTimes(c,1) = c; %matrix that has the og time slots for all courses
    multSecOgTimes(c,2) = ogTimeSlot;
end

stuMultSecInfo = cell(numCourses,1);
for n = 1 : numCourses
    %Initialize the time slots in an row vector
    AllowedTimeSlot = 1:numTimeSlots;

    %Remove the time slot related to that specific course
    ogTime = multSecOgTimes(n,2);
    AllowedTimeSlot(ogTime) = [];

    %Find how many students signed up (more than class size)
    exessNumStu = round(sol.aboveClassSize); 

    %Get the ordered time slots based on availability
    finalOrdering = funcs.getOrderedSlots(R, ST, n, ogTime,AllowedTimeSlot, 1);

    %Store the information of the number of sections and their time slots
    %for each student
    stuMultSecInfo{n,1} = funcs.getStuSec(R,ST,numStudents,n,ogTime,classSize,finalOrdering,0.75);

    %Find the actual number of sections we have after moving students around
    numSecs = numel(unique(stuMultSecInfo{n,1}(:,2))) - 1; %Minus 1 so we don't count the zero

    %Assign the actual number of sections to the course
    multSecOgTimes(n,3) = numSecs;

    %Update ST for the next round
    ST = funcs.updateST(R,ST,n,stuMultSecInfo{n,1});
end

%Print out newS
newS = funcs.getNewS(multSecOgTimes,S,numCourses,stuMultSecInfo)

%Print out the courses as a character
courseNames = funcs.getCourseNames(numCourses,multSecOgTimes)
numStuPerSec = sum(newS,1);

%Print out newT
newT = funcs.getnewT(numCourses, stuMultSecInfo,multSecOgTimes,newS,numTimeSlots)

%Create newR 
newR = funcs.getNewR(R,numStudents, newS, numCourses, multSecOgTimes,stuMultSecInfo)

%Randomly create newF
newF = funcs.getNewF(newR,facultyNum)

