function checkConflictMatrix(slotTable,Conflict)
% CHECKCONFLICTMATRIX
%
% Prints every slot together with all slots that overlap it.
%
% Inputs
%   slotTable  - Official time slot table
%   Conflict   - Conflict matrix from buildConflictMatrix

numSlots = height(slotTable);

fprintf('\n=============================================\n');
fprintf('        OFFICIAL TIME SLOT CONFLICTS\n');
fprintf('=============================================\n');

for i = 1:numSlots

    fprintf('\n---------------------------------------------\n');

    fprintf('Slot %2d\n',slotTable.SlotID(i));

    fprintf('Pattern  : %s\n',string(slotTable.Pattern(i)));
    fprintf('Days     : %s\n',string(slotTable.Days(i)));

    fprintf('Start    : %s\n',string(slotTable.Start(i)));
    fprintf('End      : %s\n',string(slotTable.End(i)));

    fprintf('\nConflicts with:\n');

    overlap = find(Conflict(i,:));

    % Remove itself
    overlap(overlap==i)=[];

    if isempty(overlap)

        fprintf('   None\n');

    else

        for j = overlap

            fprintf('   Slot %2d | %-8s | %-5s | %s - %s\n',...
                slotTable.SlotID(j),...
                string(slotTable.Pattern(j)),...
                string(slotTable.Days(j)),...
                string(slotTable.Start(j)),...
                string(slotTable.End(j)));

        end

    end

end

fprintf('\n=============================================\n');
fprintf('Total overlapping pairs = %d\n',nnz(triu(Conflict,1)));
fprintf('=============================================\n');

end

%[appendix]{"version":"1.0"}
%---
