prob = optimproblem;

studentNum = 20;
facultyNum = 4;
courseNum = 6;
classSize = 5;
numTimeSlots = 5;

F =[ 0     0     0     0     0     1;
     0     0     0     1     1     0;
     1     0     1     0     0     0;
     0     1     0     0     0     0]

S=[ 1     0     1     0     1     1;
    1     1     0     1     1     0;
    1     1     1     1     0     0;
    0     1     1     1     0     1;
    0     1     1     0     1     1;
    1     1     0     1     0     1;
    0     0     1     1     1     1;
    1     1     0     1     1     0;
    1     1     0     0     1     1;
    1     1     0     1     0     1;
    1     0     1     1     1     0;
    1     1     0     1     1     0;
    0     1     1     1     0     1;
    1     1     1     0     1     0;
    1     1     1     0     0     1;
    0     1     1     1     1     0;
    1     1     1     0     0     1;
    1     0     1     1     0     1;
    1     1     1     0     1     0;
    1     1     1     1     0     0]

R =[ 2     0     1     0     3     4;
    1     2     0     4     3     0;
    1     3     4     2     0     0;
    0     1     2     4     0     3;
    0     3     2     0     1     4;
    4     3     0     2     0     1;
    0     0     2     3     4     1;
    3     1     0     2     4     0;
    2     1     0     0     4     3;
    2     3     0     4     0     1;
    1     0     3     4     2     0;
    4     3     0     1     2     0;
    0     2     3     4     0     1;
    2     1     4     0     3     0;
    3     2     1     0     0     4;
    0     3     4     1     2     0;
    4     1     3     0     0     2;
    1     0     4     3     0     2;
    1     4     2     0     3     0;
    1     2     3     4     0     0]

%Create random S and R matrices
% S = zeros(studentNum,courseNum);
% R = zeros(studentNum,courseNum);
% for i = 1:studentNum
%     % Randomly choose 4 positions for 1's
%     idx = randperm(courseNum,4);
%     % Build S
%     S(i,idx) = 1;
%     % Random ranking 1,2,3,4
%     ranks = randperm(4);
%     % Put rankings in the same locations as the 1's
%     R(i,idx) = ranks;
% end
% disp('S =')
% disp(S)

%Transform the matrix R to have the entries 2,4,6,7
TR = R;
TR(R==1) = 2;
TR(R==2) = 4;
TR(R==3) = 6;
TR(R==4) = 7;
disp('TR =')
disp(TR)

%Define the needed unit vectors
uFaculty = ones(facultyNum,1);
uClasses = ones(courseNum,1);
uStudents = ones(studentNum,1);
M = classSize * uClasses;
studentLoads = sum(S,2);
classLoads = sum(S)';

%Encoding the time slots a student is able to take a course in. 
T = optimvar('T',courseNum,numTimeSlots,'Type','integer','LowerBound',0,'UpperBound',1);

%Create the penalty vectors as column vectors
aboveClassSize = optimvar('aboveClassSize',courseNum,1,'Type','integer','LowerBound',0);

%define the alpha penlaty vector
A = optimvar('A',studentNum,numTimeSlots,'Type','integer','LowerBound',0);

%Define the beta penalty vector
B = optimvar('B',facultyNum,numTimeSlots,'Type','integer','LowerBound',0);

%Define the penalty vectors for R
Psi = optimvar('Psi',studentNum,numTimeSlots,'Type','integer','LowerBound',0);

%Create the time slot constraint: no class should be in two time slots
prob.Constraints.timeSlotCnstr = sum(T,2) == uClasses; % sum the columns

%Capture how many students exceed the class size
prob.Constraints.classSizeCnstr = sum(S)' - aboveClassSize <= M;

%How many students have a conflict in one time slot
for s = 1:numTimeSlots
    prob.Constraints. (sprintf('studentTimeCnstr%d',s)) = S*T(:,s) <= uStudents + A(:,s);
end

%Required: the times at which faculty at able to teach in
for s = 1:numTimeSlots
    prob.Constraints.(sprintf('facultyTimeCnstr%d',s)) = F*T(:,s) <= uFaculty; %+ B(:,s);
end

%Define the constraints for the ranking matrix R
for s = 1:numTimeSlots
    prob.Constraints.(sprintf('preferenceSlot%d',s)) = TR*T(:,s) <= 7*uStudents + Psi(:,s);
end


%Define the objective function we want to minimize, and solve it
prob.ObjectiveSense = "minimize";
prob.Objective = sum(aboveClassSize,"all")+5*sum(A,'all')+5*sum(Psi,'all');
sol = solve(prob);

%Display results

disp("number of students who exceed the class size")
disp(round(sol.aboveClassSize))

disp("Show the values of t1, t2, t3 to check where the classes are assigned.")
disp(round(sol.T))

disp("How many students have a conflict in each time slot.")
disp(round(sol.A))

disp("Print out Psi.")
disp(round(sol.Psi))

%Create ST: shows the schedule for each student
ST = [];
for t = 1 : numTimeSlots
    tclasses = funcs.getColsInP(R,round(sol. T(:,t)),studentNum);
    ST(:,t)=funcs.getStudentTimeSlot(tclasses,0);
end

%Find the time slot given by the initial solution
multSecOgTimes = [];
for c = 1 : courseNum
    [~, ogTimeSlot] = find(round(sol.T(c,:)) == 1);
    multSecOgTimes(c,1) = c; %matrix that has the og time slots for all courses
    multSecOgTimes(c,2) = ogTimeSlot;
end


% checkingMatrix = zeros(studentNum,2);
% checkingMatrix(:,1) = R(:,multiSecCourse);
% for i = 1 : studentNum
%     timeSlot = StuMultSecSelec(i,3);
%     if timeSlot ~= 0
%         checkingMatrix(i,2) = ST(i,timeSlot);
%     end
% end
% disp("Form [R| newST]") 
% disp(checkingMatrix)

stuMultSecInfo = cell(courseNum,1);
for n = 1 : courseNum
    %Initialize the time slots in an row vector
    AllowedTimeSlot = [1 2 3 4 5];

    %Remove the time slot related to that specific course
    ogTime = multSecOgTimes(n,2);
    AllowedTimeSlot(ogTime) = [];

    %Find how many students signed up (more than class size)
    exessNumStu = round(sol.aboveClassSize); 

    %Get the ordered time slots based on availability
    finalOrdering = funcs.getOrderedSlots(R, ST, n, ogTime,AllowedTimeSlot, 1);

    %Store the information of the number of sections and their time slots
    %for each student
    stuMultSecInfo{n,1} = funcs.getStuSec(R,ST,studentNum,n,ogTime,classSize,finalOrdering,0.75);
    
    %Find the actual number of sections we have after moving students around
    numSecs = numel(unique(stuMultSecInfo{n,1}(:,2))) - 1; %Minus 1 so we don't count the zero

    %Assign the actual number of sections to the course
    multSecOgTimes(n,3) = numSecs;

    %Update ST for the next round
    ST = funcs.updateST(R,ST,n,stuMultSecInfo{n,1});
end

%Print out newS
newS = funcs.getNewS(multSecOgTimes,S,courseNum,stuMultSecInfo)

%Print out the courses as a character
courseNames = funcs.getCourseNames(courseNum,multSecOgTimes)
numStuPerSec = sum(newS,1);

%Print out newT
newT = funcs.getnewT(courseNum, stuMultSecInfo,multSecOgTimes,newS,numTimeSlots)

%Create newR 
newR = funcs.getNewR(R,studentNum, newS, courseNum, multSecOgTimes,stuMultSecInfo)

%Randomly create newF
newF = funcs.getNewF(newR,facultyNum)

