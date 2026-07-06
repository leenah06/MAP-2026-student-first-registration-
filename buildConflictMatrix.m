function Conflict = buildConflictMatrix(slotTable)
% BUILDCONFLICTMATRIX
% Conflict(i,j)=1 if Slot i and Slot j overlap in time.

numSlots = height(slotTable);

Conflict = false(numSlots,numSlots);

for i = 1:numSlots

    for j = i:numSlots

        %% Same meeting day?

        days1 = char(slotTable.Days(i));
        days2 = char(slotTable.Days(j));

        dayOverlap = false;

        % Monday
        if contains(days1,'M') && contains(days2,'M')
            dayOverlap = true;
        end

        % Tuesday
        if contains(days1,'T') && contains(days2,'T')
            dayOverlap = true;
        end

        % Wednesday
        if contains(days1,'W') && contains(days2,'W')
            dayOverlap = true;
        end

        % Thursday (R)
        if contains(days1,'R') && contains(days2,'R')
            dayOverlap = true;
        end

        % Friday
        if contains(days1,'F') && contains(days2,'F')
            dayOverlap = true;
        end

        %% Time overlap?

        timeOverlap = ...
            slotTable.Start(i) < slotTable.End(j) && ...
            slotTable.Start(j) < slotTable.End(i);

        %% Store

        if dayOverlap && timeOverlap
            Conflict(i,j) = true;
            Conflict(j,i) = true;
        end

    end

end

end

%[appendix]{"version":"1.0"}
%---
