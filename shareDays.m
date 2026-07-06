function tf = shareDays(days1,days2)
% Returns true if two day patterns share at least one day.

days1 = char(days1);
days2 = char(days2);

tf = false;

% Monday
if contains(days1,'M') && contains(days2,'M')
    tf = true;
end

% Tuesday
if contains(days1,'T') && ~contains(days1,'TH') ...
        && contains(days2,'T') && ~contains(days2,'TH')
    tf = true;
end

% Wednesday
if contains(days1,'W') && contains(days2,'W')
    tf = true;
end

% Thursday
if contains(days1,'TH') && contains(days2,'TH')
    tf = true;
end

% Friday
if contains(days1,'F') && contains(days2,'F')
    tf = true;
end

end

%[appendix]{"version":"1.0"}
%---
