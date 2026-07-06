function allowed = getAllowedSlots(pattern,slotTable)
% GETALLOWEDSLOTS
% Returns the allowed slot IDs for a meeting pattern.

allowed = slotTable.SlotID(slotTable.Pattern==string(pattern));

end

%[appendix]{"version":"1.0"}
%---
