% Copyright 2013, 2014, 2015, 2016 Thomas M. Mosier, Kendra V. Sharp, and 
% David F. Hill
% This file is part of multiple packages, including the GlobalClimateData 
% Downscaling Package, the Hydropower Potential Assessment Tool, and the 
% Conceptual Cryosphere Hydrology Framework.
% 
% The above named packages are free software: you can 
% redistribute it and/or modify it under the terms of the GNU General 
% Public License as published by the Free Software Foundation, either 
% version 3 of the License, or (at your option) any later version.
% 
% The above named packages are distributed in the hope that it will be 
% useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with the Downscaling Package.  If not, see 
% <http://www.gnu.org/licenses/>.

function blCal = cal_class(strCal)



%Input:
%'strCal' = string describing calendar

%Output: 
%   0 = Gregorian Calendar (one day leap year every four years, but not on years where mod(yr,100)=0)
%   1 = 365 day calendar (also referred to as 'noleap'
%   2 = 360 day calendar
%   3 = Julian Calendar (one day leap year every four years)

%Default to gregorian calendar:
if ~isempty(regexpi(strCal,'gregorian')) || ~isempty(regexpi(strCal,'standard'))
    blCal = 0;
elseif regexpbl(strCal, {'365','noleap','no_leap'})
    blCal = 1;
elseif ~isempty(regexpi(strCal,'360'))
    blCal = 2;
elseif ~isempty(regexpi(strCal,'julian'))
    blCal = 3;
else
    blCal = nan;
    warning('days_2_date:calendar',['The calendar used in the current '...
        'NetCDF file is ' char(39) strCal char(39) ', which has not been ' ...
        'programmed for.  Please add this in the current function.']);
end