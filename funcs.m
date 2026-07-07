classdef funcs
    methods(Static)

        %Create a function that would extract the columns of P that are scheduled
        %in that time slot
        function[extractedCols] = getColsInP(P,t, numOfStudents)
            %Find the number of nonzero entries in t
            nonzeros = 0;
            wantedIndeces = []; 
            for i = 1:length(t)
                if(t(i) == 1)
                    nonzeros = nonzeros + 1;
                    wantedIndeces(end+1) = i;
                else
                    continue
                end
            end
        
            %Transfer the wanted columns of P into subOfP
            subOfP = zeros(numOfStudents,nonzeros);
            for j=1 :nonzeros
                subOfP(:,j) = P(:,wantedIndeces(j));
                extractedCols = subOfP;
            end
        end
            
        %Create a function that creates a 2D list of empty spots
        function[FreeSpots] = rankFreeSpots(R)
        %Empty matrix that will hold the ranked free spots for students
        FreeSpots = [];
        for i = 1 : size(R, 1)
            currentRow = R(i, :); 
            [~, idx] = sort(currentRow);
            %populate each row of FreeSpots with the min of R in ascending order
            FreeSpots(i, :) = idx;
        end
    end

    
        %This function tells us which courses each student will take in each time
        %slot based on their preference/ by ranking 
        function[RPrime] = getStudentTimeSlot(RT, fixedCol)
        %Declare the matrix that will hold the courses taken by each student in
            %each time slot
            RPrime = [];
            for j = 1 : size(RT,1)
                RPrime(j,1) = max(RT(j, :));
            end
            if fixedCol ~=0
                RPrime = RT(:,fixedCol);
            end
        end
    
        %create a function that counts the number of people who have a conflict
        %based on the type of conflict
        function[numConflicts] = getNumConflicts(RT)
            numConflicts=[];
            typeOne = [1 2; 2 1; 1 3; 3 1; 1 4;4 1];
            countType1 = 0;
            
            typeTwo = [2 3; 3 2; 2 4; 4 2];
            countType2 = 0;
            
            typeThree = [3 4; 4 3];
            countType3 = 0;
            
            if size(RT,2) ~= 1
                for i = 1 : size(RT,1)
                    if ismember(RT(i,:),typeOne,'rows')
                        countType1=countType1+1;
                    end
                
                    if ismember(RT(i,:),typeTwo,'rows')
                        countType2=countType2+1;
                    end
                
                    if ismember(RT(i,:),typeThree,'rows')
                        countType3=countType3+1;
                    end
                end
            end
            numConflicts(:,1) = countType1;
            numConflicts(:,2) = countType2;
            numConflicts(:,3) = countType3;
        end

        function[MostOccurrElets] = getModes(OrderedTimeSlots)
            % Unique values and their frequencies
            [vals,~,idx] = unique(OrderedTimeSlots);
            counts = accumarray(idx,1);

            % Sort by frequency (largest first)
            [frequency, order] = sort(counts,'descend');
            MostOccurrElets(1,:) = vals(order)';
            MostOccurrElets(2,:) = frequency;
        end

        %Create a matrix with selected rows removed
        function[remainingRows] = removeRows(A, selectedRows)
            remainingRows = A;
            remainingRows(selectedRows, :) = [];
        end

        %Not used
        function[stats] = getStats(R,T,numOfStudents,ignoredCol,timeSlotNum)
            NumConflicts = [0 0 0]; %[Type 1, Type 2, Type 3]
            StudentTimeSlots = [];

            for i = 1 : size(T,2)
                %Extract the columns corresponding to the classes in that time slot
                disp((sprintf('Extracted Columns for t%d',i)))
                ExtCols = funcs.getColsInP(R,round(T(:,i)),numOfStudents);

                %Put the course with higher importance in the corresponding slot
                StudentTimeSlots(:,i) = funcs.getStudentTimeSlot(ExtCols,ignoredCol);

                %Get the number of conflicts of each type
                NumConflicts = NumConflicts + (funcs.getNumConflicts(ExtCols)/numOfStudents)*100;
            end

            %Find the timeslot that is free for most student
            disp("Matrix of the courses each students is taking in each time slot:")
            disp(StudentTimeSlots)

            OrderedTimeSlots= funcs.rankFreeSpots(StudentTimeSlots)
            disp("The spot that's empty for most students is:")

            %MostEmptySpot = mode(OrderedTimeSlots(:,1)) %Make function that would provide the 'freeist' spots IN ORDER
            ModesOrdered = funcs.getModes(OrderedTimeSlots(:,1));
            disp(ModesOrdered)

            stats = NumConflicts;
        end

        function[categStudents] = findOverEnrStu(ST,col, classSize)
            categStudents = [];
            chosenCol = ST(:,col);
            [~, idx] = sort(chosenCol,'descend');
            categStudents = idx(1:classSize)';
        end
    
        %Create a function that would tell us how many sections we need
        function[numSections] = getNumSections(numStudents, classSize, miCapacity)
            numSections = 1;
            studentsLeft = numStudents;
            numStuPerSec = ceil(miCapacity*classSize);
            while studentsLeft >= classSize
                numSections = numSections + 1;
                studentsLeft = studentsLeft - 5;
            end
        end

        %Creates the matrix W such that [R | the students schedule in a time slot]
        function[W] = getW(R,ST,courseNum,currentSlot,AddSlot)
            W=[];
            W(:,1)=R(:,courseNum); %Make the first column the column of R that corresponds to that course
            W(:,2)=ST(:,currentSlot); %Make the second column the column of ST that corresponds to the 
            % time slot that course is in
            %Add additional time slots if we want to compare multiple time
            %slots
            if ~isempty(AddSlot)
                for elet = 1 : size(AddSlot,2)
                    currentSlot = AddSlot(1,elet);
                    W(:,2+elet)=ST(:,currentSlot);
                end
            end
        end

        %Order the students in a category in ascending order based on the
        %conflict. The first student will have the least conflict.
        function[orderedCateg] = orderCategories(category, ranking)
            orderedCateg = [];
            if ~isempty(category)
                [~,idx] = sort(ranking);   % sort in ascending order
                orderedCateg = category(:,idx);
            end
        end

        function[Categories] = getCatCell(W, currentSlot, AddSlot)

            Categories = cell(1,6); 
            Categ1=[]; %In the first timeslot, can move with 0 conflict
            Categ2=[]; %In the first timeslot, can move with 1/2 conflict
            Categ3=[]; %NOT in the first timeslot, can move with 0 conflict
            Categ4=[]; %NOT in the first timeslot, can move with 1/2 conflict
            Categ5=[]; %In the first time slot and cannot move
            notWantingCourse = [];

            if size(W,2) < 3 %Check if we have only two columns (not checking against potential time slots)
                for i = 1 : size(W,1)
                    wantedC = W(i,1);
                    if wantedC == 0
                        notWantingCourse(end+1) = i;
                    end
                end
            else
                %Suppose the ranking is unique
                for stu = 1 : size(W,1)
                    wantedC = W(stu,1);
                    currentC = W(stu,2);
                    otherC = W(stu,3);
    
                    if wantedC == 0 
                        notWantingCourse(end+1) = stu;
                        % fprintf('S%d: doesnt want the course \n', stu)

                    elseif (wantedC == currentC) && (currentC > otherC)
                        if otherC == 0
                            Categ1(end+1) = stu;
                            % fprintf('S%d: In t%d, can move to t%d with 0 conflict \n', stu, currentSlot, AddSlot)
                        elseif otherC ~= 3 
                            Categ2(1,end+1) = stu;
                            Categ2(2,end) = otherC;
                            % fprintf('S%d: In t%d, can move to t%d with rank-%d conflict \n', stu, currentSlot, AddSlot, otherC)
                        else
                            Categ5(1,end+1) = stu;
                            Categ5(2,end) = otherC;
                            % fprintf('S%d: In t%d, can NOT move to t%d\n', stu, currentSlot, AddSlot)
                        end

                    elseif (wantedC ~= currentC) && (wantedC > otherC)
                        if otherC == 0
                            Categ3(end+1) = stu;
                            % fprintf('S%d: NOT in t%d, can move to t%d with 0 conflict \n', stu, currentSlot, AddSlot)
                        elseif otherC ~= 3
                            Categ4(1,end+1) = stu;
                            Categ4(2,end) = otherC;
                            % fprintf('S%d: NOT in t%d, can move to t%d with rank-%d conflict \n', stu, currentSlot, AddSlot, otherC)
                        else
                            Categ5(1,end+1) = stu;
                            Categ5(2,end) = otherC;
                            % fprintf('S%d: In t%d, can NOT move to t%d\n', stu, currentSlot, AddSlot)
                        end

                    else
                        Categ5(1,end+1) = stu;
                        Categ5(2,end) = otherC;
                        % fprintf('S%d: In t%d, can NOT move to t%d\n', stu, currentSlot, AddSlot)
                    end
                end
            end
            %Order the categories if they're not empty
            
            if ~isempty(Categ2)
                Categ2 = funcs.orderCategories(Categ2(1,:), Categ2(2,:));
            end 

            if ~isempty(Categ4)
                Categ4 = funcs.orderCategories(Categ4(1,:), Categ4(2,:));
            end

            if ~isempty(Categ5)
                Categ5 = funcs.orderCategories(Categ5(1,:), Categ5(2,:));
            end

            %Diplaying results
            % disp("-----------------------------------------------------------")
            % fprintf('In the first timeslot, can move with 0 conflict. %d students:\n', size(Categ1,2))
            % disp([Categ1])
            % fprintf('In the first timeslot, can move with 1/2/3 conflict. %d students:\n', size(Categ2,2))
            % disp([Categ2])
            % fprintf('NOT in the first timeslot, can move with 0 conflict. %d students:\n', size(Categ3,2))
            % disp([Categ3])
            % fprintf('NOT in the first timeslot, can move with 1/2/3 conflict. %d students:\n', size(Categ4,2))
            % disp([Categ4])
            % fprintf('In the first time slot and cannot move. %d students:\n', size(Categ5,2))
            % disp([Categ5])
            % fprintf('Doesnt want the course. %d students:\n', size(notWantingCourse,2))
            % disp([notWantingCourse])

            Categories{1} = Categ1;
            Categories{2} = Categ2;
            Categories{3} = Categ3;
            Categories{4} = Categ4;
            Categories{5} = Categ5;
            Categories{6} = notWantingCourse;
        end


        function[StuMultSecSelec] = getStuSec(R,ST,studentNum,courseNum,ogTimeSlot, classSize,AllowedTimeSlot,minCapacity)
            %Define the min number of students per section
            % minStuPerSec = ceil(minCapacity*classSize); %test for now
            minStuPerSec = classSize;

            StuMultSecSelec = zeros(studentNum,3);
            sectionCount = 2;
            %Go thru each time slot in the order of most available to least
            for i = 1 : size(AllowedTimeSlot,2)
                %Define a conditional that checks if a student is assigned
                %in this section
                assignedThisSection = false;

                %Initialize important variables
                currTimeSlot = AllowedTimeSlot(1,i);
                W = funcs.getW(R,ST,courseNum,ogTimeSlot,[currTimeSlot]);
                Categories = funcs.getCatCell(W, ogTimeSlot, currTimeSlot);

                %Place the students who cant move in the initial section
                %only in the first round
                unmovedStu = Categories{5};
                if i == 1  
                    stuPerSec = 0;
                    for h = 1 : size(unmovedStu,2)
                        currStu = unmovedStu(1,h);
                        if stuPerSec < minStuPerSec
                            StuMultSecSelec(currStu,3) = ogTimeSlot; %Assign time slot
                            StuMultSecSelec(currStu,2) = 1; %Assign section
                            stuPerSec = stuPerSec + 1;
                        end
                    end
                end

                %Number of students in the first (most available) section
                zeroConfStu = [Categories{1}, Categories{3}]; %Indices of students who can move with 0 conflict
                stuPerSec = 0;
                for j = 1 : size(zeroConfStu,2)
                    currStu = zeroConfStu(1,j);
                    if (stuPerSec < minStuPerSec) && (StuMultSecSelec(currStu,2) == 0)
                        StuMultSecSelec(currStu,3) = currTimeSlot; %Assign time slot
                        StuMultSecSelec(currStu,2) = sectionCount; %Assign section
                        assignedThisSection = true;
                        stuPerSec = stuPerSec + 1;
                    end
                end
                
                %If there is space in the section after placing the
                %0-conflict students, place the students who have some
                %conflict
                someConfStu = [Categories{2}, Categories{4}]; %Indices of students who can move with 1/2/3 conflict (ordered)

                if stuPerSec < classSize 
                    for k = 1 : size(someConfStu,2)
                        currStu = someConfStu(1,k);
                        if (stuPerSec < minStuPerSec) && (StuMultSecSelec(currStu,2) == 0)
                            StuMultSecSelec(currStu,3) = currTimeSlot; %Assign time slot
                            StuMultSecSelec(currStu,2) = sectionCount; %Assign section
                            assignedThisSection = true;
                            stuPerSec = stuPerSec + 1;
                        end
                    end
                end
                %Only change the incerment of sections if there are students
                %who can be placed there
                if assignedThisSection
                    sectionCount = sectionCount + 1;
                end
            end
            
            StuMultSecSelec(:,1) = courseNum;
        end

        %Returns a matrix/array, NOT a cell
        function[orderedTimeSlots] = findOverallBestTime(R, ST, courseNum,SecOneTimeSlot,numTimeSlots, categType)
            
            %Declare the cell that will hold the categories for each time
            %slot
            AllTimeSlotsCateg = cell(2,size(numTimeSlots,2));

            %Find the categories for each time slot
            for i = 1 : size(numTimeSlots,2) %Loop thru however many time slots we have (minus og)
                W = funcs.getW(R,ST,courseNum,SecOneTimeSlot,[i]);
                otherTimeSlot = numTimeSlots(1,i);
                AllTimeSlotsCateg{1,i} = otherTimeSlot;
                AllTimeSlotsCateg{2,i} = funcs.getCatCell(W,SecOneTimeSlot,otherTimeSlot);
            end

            %Order the time slots based on most availability with 0
            %conflicts
            numOfZeroConfStu = [];
            for j = 1 : size(numTimeSlots,2)
                currCateg = AllTimeSlotsCateg{2,i};
                numOfZeroConfStu(1,i) = size(currCateg{categType},2) + size(currCateg{categType+2},2);
            end

            orderedTimeSlots(1,:) = flip(funcs.orderCategories([AllTimeSlotsCateg{1,:}],numOfZeroConfStu));
            orderedTimeSlots(2,:) = flip(numOfZeroConfStu);
            
        end

        %Returns an array/matrix, not a cell
        function[finalOrdering] = getOrderedSlots(R, ST, courseNum,SecOneTimeSlot,numTimeSlots, categType)
            finalOrdering = {}; %Create an empty cell such that the first 'row' is the ordering of timeslots, 
            %and the second row is the frequency, and the third row is the categories

            %Find the ordering based on the 0-conflicts
            initialOrder = funcs.findOverallBestTime(R, ST, courseNum,SecOneTimeSlot,numTimeSlots, categType);

            %Find the index where duplication (of num of students with zero
            %conflict starts)
            dupStartIdx = find(diff(initialOrder(2,:))==0, 1);

            %Copy the first ordering until the index of duplication
            finalOrdering = initialOrder(:,[1:dupStartIdx-1]);

            %Save the initial result of time slots only without frequency 
            firstRsult = initialOrder(1,:);

            %Remove the time slots found in the first ordering, only keep
            %the ties
            newTimeSlotSearch = firstRsult(1,[dupStartIdx : end]);

            %Find the ordering of the remaining time slots based on number
            %of students who have 1/2/3 conflicts
            secondResult = funcs.findOverallBestTime(R, ST, courseNum,SecOneTimeSlot,newTimeSlotSearch, 2);

            %Chain the second ordering to the first
            % finalOrderingMatrix = [finalOrdering,secondResult];

            % finalOrdering = finalOrderingMatrix(1,:);
            finalOrdering = [finalOrdering,secondResult];
        end

        function[newS] = getNewS(multSecOgTimes,S, numOfCourse,MultSecInfo)
            rows = size(S,1); %Number of students
            cols = round(sum(multSecOgTimes(:,3)));
            newS = zeros(rows,cols);
            newCol = 1 ;
            %Loop thru all columns in the new array
            for c = 1 : numOfCourse 
                numSec = multSecOgTimes(c,3);
                %Copy unporblematic columns
                if numSec == 1 
                    newS(:,newCol) = S(:,c);
                else 
                    for stu = 1 : rows
                        stuMultSecInfo = MultSecInfo{c};
                        addSec = stuMultSecInfo(stu,2);
                        if addSec > 0
                            newS(stu,newCol+addSec-1) = 1; 
                        end 
                    end
                end 
                newCol = newCol + numSec;
            end
        end

        %Returns a cell where each element has the form 'cij' where
        %i=course number, and j= section number
        function[courseNames] = getCourseNames(numOfCourses, multSecOgTimes)
            courseNames = {};
            newCol = 1;
            for i = 1 : numOfCourses
                numSec = multSecOgTimes(i,3);
                if numSec == 1
                    courseNames{newCol } = append('c',num2str(i));
                    newCol = newCol + 1;
                else
                    for s = 1 : numSec
                        courseNames{newCol +s-1} = append('c',num2str(i),num2str(s));
                    end
                    newCol = newCol + numSec;
                end
            end
        end

        %Updates the schedule of students after a round of creating
        %sections, places the students into a section.
        function[updatedST] = updateST(R,ST,multiSecCourse,StuMultSecSelec)
            updatedST = ST;
            for w = 1 : size(ST,2)
                ranking = R(w, multiSecCourse);
                %New time slot for the section
                newTimeSlot = StuMultSecSelec(w,3);
                %Put the course in the right time slot
                if(newTimeSlot > 0)
                    oldSlot = find(ST(w,:) == ranking);
                    updatedST(w,oldSlot) = 0;
                    updatedST(w,newTimeSlot) = ranking;
                end
            end
        end

        function[newT] = getnewT(numOfCourses, StuMultSecSelec,multSecOgTimes,newS,numOfTimeslots)
            %Initialize the matrix that holds the time slots for the sections
            newT = zeros(size(newS,2),numOfTimeslots);
            numRow = 0;
            %Go thru each of the courses
            for c = 1 : numOfCourses
                currCourseInfo = StuMultSecSelec{c,1}; %Multisection info
                numSections = multSecOgTimes(c,3); %number of sections for the current course
                for s = 1 : numSections
                    k = find(currCourseInfo(:,2) == s);
                    secIdx = k(1);
                    %The time slot for the current section
                    sectionTimeSlot = currCourseInfo(secIdx,3); %works now
                    
                    newT(numRow+secIdx,sectionTimeSlot) = 1;
                end
                numRow = numRow + numSections;
            end
        end

        function[newR] = getNewR(R,studentNum, newS, courseNum, multSecOgTimes,stuMultSecInfo)
            % Create a new R matrix randomly based on the updated student preferences
            newR = zeros(studentNum, size(newS,2));

            %Loop thru all columns in the new array
            newCol = 1 ;
            for c = 1 : courseNum 
                numSec = multSecOgTimes(c,3);
                %Copy unporblematic columns
                if numSec == 1 
                    newR(:,newCol) = R(:,c);
                else 
                    for stu = 1 : studentNum
                        ranking = R(stu,c); %Save what the student ranked the course as in R
                        smsi = stuMultSecInfo{c};
                        addSec = smsi(stu,2);
                        if addSec > 0
                            newR(stu,newCol+addSec-1) = ranking; %Place the ranking in the section the student is in
                        end 
                    end
                end 
                newCol = newCol + numSec;
            end 
        end

        function[newF] = getNewF(newR,facultyNum)
            newF = zeros(facultyNum,size(newR,2));
            for f = 1:size(newR,2)
                %Want to have only one nonzero entry per column.
                randRow = randi(facultyNum);
                %Check if that faculty is assigned a course
                isScheduled = find(newF(randRow,:) == 1);
                if isempty(isScheduled)
                    newF(randRow, f) = 1;
                else
                    randRow = randi(facultyNum);
                    newF(randRow, f) = 1;
                end
            end
        end
    end
end




