function coursePattern = extractMeetingPatterns(courseDataFiltered,uniqueTrueIDs)
% EXTRACTMEETINGPATTERNS
% Returns the meeting pattern (timeCode1) for every unique course.
%
% Input:
%   courseDataFiltered
%   uniqueTrueIDs
%
% Output:
%   coursePattern(c) = timeCode1 for course c

numCourses = length(uniqueTrueIDs);

coursePattern = strings(numCourses,1);

% Find where each unique course appears in courseDataFiltered
[~,loc] = ismember(uniqueTrueIDs,courseDataFiltered.trueRegID);

for c = 1:numCourses

    idx = loc(c);

    if idx==0
        continue
    end

    tc = string(courseDataFiltered.timeCode1(idx));

    % Standardize known inconsistent codes
    if tc=="50.01667MWF"
        tc="50MWF";
    end

    coursePattern(c)=tc;

end

end

%[appendix]{"version":"1.0"}
%---
