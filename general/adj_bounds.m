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

function [bDd, bInd] = adj_bounds(hdr,bndsDd,clipTyp)



%Adjusts user defined boundaries so they fit the data frame
%hdr = 6 array matrix of header elements in standard ESRI format
%Bu = bounding box specified in decimal degrees [lonW, lonE, latS, latN]
%clip = string with either options: 'in' or 'out' specifying if the new
    %alignment should fall inside of or outside of the original
    
%bDd = bounds of output grid in format [lonW, lonE, latS, latN], where each
%coordinate refers to the center of the oustide row/column
%bInd = indices that will clip the original data matrix to the desired 
%region (i.e. matNew = matOrg(bInd(4) : bInd(3), bInd(1) : bInd(2)) )

ncols = hdr(1);
nrows = hdr(2);
xcor  = hdr(3);
ycor  = hdr(4);
dxy   = hdr(5);

vecLon = xcor + 0.5*dxy : dxy : xcor + (ncols-0.5)*dxy;
vecLat = ycor + (nrows-0.5)*dxy : -dxy : ycor + 0.5*dxy;

%Find indices that are within the desired region:
if regexpbl('out',clipTyp)
    indW = find(vecLon <= min(bndsDd(1:2)) - 0.5*dxy, 1, 'last');
    indE = find(vecLon >= max(bndsDd(1:2)) + 0.5*dxy, 1, 'first');
    indS = find(vecLat <= min(bndsDd(3:4)) - 0.5*dxy, 1, 'first');
    indN = find(vecLat >= max(bndsDd(3:4)) + 0.5*dxy, 1, 'last');
elseif regexpbl('in',clipTyp)
    indW = find(vecLon >= min(bndsDd(1:2)) + 0.5*dxy, 1, 'first');
    indE = find(vecLon <= max(bndsDd(1:2)) - 0.5*dxy, 1, 'last');
    indS = find(vecLat >= min(bndsDd(3:4)) + 0.5*dxy, 1, 'last');
    indN = find(vecLat <= max(bndsDd(3:4)) - 0.5*dxy, 1, 'first');
else
    error('adj_bounds:invalidClipOpt','Invalid clipping option selected.')
end
if isempty(indW)
   indW = 1; 
end
if isempty(indE)
   indE = numel(vecLon); 
end
if isempty(indS)
   indS = numel(vecLat); 
end
if isempty(indN)
   indN = 1; 
end

bDd = [vecLon(indW), vecLon(indE), vecLat(indS), vecLat(indN)];
bInd = [indW, indE, indS, indN];



