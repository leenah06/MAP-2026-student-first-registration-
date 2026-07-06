function slotTable = buildSlotTable()

slotTable = readtable("OfficialTimeSlots.xlsx");
slotTable.Properties.VariableNames = ["SlotID","Pattern","Days","Start","End","Duration"];

slotTable.Pattern = string(slotTable.Pattern);
slotTable.Days    = string(slotTable.Days);

end

%[appendix]{"version":"1.0"}
%---
