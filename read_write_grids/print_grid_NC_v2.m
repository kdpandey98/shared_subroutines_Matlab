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

function print_grid_NC_v2(pathData, data, var, lon, lat, dateVec, dateBnds, varargin)


%Creates NetCDF geo-referenced climate data file using data and metadata
%provided by inputs.

%INPUTS:
%path = Full filepath (including extension) for desired output .nc file
%data = 2D or 3D array. If 3D, first index is time (indice 1 is earliest time)
        %In remaining two indexes, 1st is lat and 2nd is lon. 
        %oriented with North = indice 1 and West = indice 1
%var = Name that the data variable should take in the NetCDF file
%lon = Vector of longitude values corresponding to data
%lat = Vector of latitude values corresponding to data
%timeVec = 2D array. First index corresponds to separate dates, 2nd index represents time unit for a given date.
        %For daily data, 2nd index has format [year, month, day].
        %For hourly data, 2nd index has format [year, month, day, hour]
%varargin = Two possibilities:   
        %(1) a string specifying units of data variable.
        %(2) a number corresponding to decimal places to use in coding data.

prec = nan;
units = nan;
if iscell(varargin) && ~isempty(varargin)
    for ii = 1 : numel(varargin(:))
        if ischar(varargin{ii})
            units = varargin{ii};
        elseif isnumeric(varargin{ii})
            prec = varargin{ii};
        end
    end
end


%Select data type to use (default is single precision):
if ~isnan(prec)
    if prec == -1
        dataTyp = 'uint16';
        filVal = intmax(dataTyp); %Missing data value (all NaN values go to this):
    elseif prec == 0
        dataTyp = 'int16';
        filVal = intmax(dataTyp); %Missing data value (all NaN values go to this):
    elseif prec > 0 && prec < 5
        dataTyp = 'single';
        filVal = flintmax(dataTyp); %Missing data value (all NaN values go to this):
    else
        dataTyp = 'double';
        filVal = flintmax(dataTyp); %Missing data value (all NaN values go to this):
    end
elseif regexpbl(char(var),{'pre','pr'})
    dataTyp = 'uint16';
    filVal = intmax(dataTyp); %Missing data value (all NaN values go to this):
    prec = 0;
else
    dataTyp = 'single';
    filVal = flintmax(dataTyp); %Missing data value (all NaN values go to this):
    prec = 4;
end    


% %Initialize:
% ovrWrt = '';

% %If file exists and dimensions are different, ask if it should be
% %overwritten:
% if exist(pathData,'file')
%     
%     ds = ncdataset(pathData);
%     [gcmLat, ~] = NC_lat(ds);
%     [gcmLon, ~] = NC_lon(ds);
%     if ~isequal(lon, gcmLon) || ~isequal(lat,gcmLat)
%         pathDisp = strrep(pathData, filesep, [filesep filesep]);
%     	ovrWrt = input(['The file ' pathDisp ' exists with different ' ...
%             'dimensions than the data being written to it.' char(10) ...
%             'Overwrite this file (Y or N)'],'s'); %#ok<NASGU>
%         if isempty(regexpi(ovrWrt,'y'))
%             disp(['The file ' pathData ' is not being overwritten and the data ' ...
%                 'is therefore not being stored to a file.']);
%             return
%         elseif ~isempty(regexpi(ovrWrt,'y'))
%             clear ds
%             delete(pathData)
%         end
%     end
% end
    


%Define NetCDF File Variables or indices for writing extra data:
if ~exist(pathData,'file')
    [pathCrt, ~, ext]= fileparts(pathData);
    if ~exist(pathCrt,'dir')
        mkdir(pathCrt);
    end
    
    if ~regexpbl(ext, 'nc')
        pathData = [pathData '.nc'];
    end
    
    strtTime = 1;
    strtData = [1,1,1];
%     strtData = ones(numel(size(data)),1);
    
    strFormat = 'netcdf4';     
    %Not sure why to use 'format' = 'classic' vs. 'format' = 'netcdf4' 
    %(if using the latter, 'ChunkSize' = length of each dimension)
    
    %Define attributes:
    nccreate(pathData, var, 'Dimensions', ...
        {'time' Inf 'lat' length(lat(:)) 'lon' length(lon(:))}, ...
        'Format', strFormat, 'Datatype', dataTyp, 'FillValue', filVal); 
    
%     %Redefine chunksize:
%     ncid = netcdf.open(pathData,'NC_WRITE');
%     varid = netcdf.inqVarID(ncid,char(var));
%     netcdf.defVarChunking(ncid,varid,'CONTIGUOUS'); 
%     netcdf.close(ncid);
    
    nccreate(pathData,'time','Dimensions',{'time' Inf}, ...
        'Format',strFormat, 'Datatype', 'double');
    
    nccreate(pathData,'time_bnds','Dimensions',{'ntb' 2 'time' Inf}, ...
        'Format',strFormat, 'Datatype', 'double');
    
    nccreate(pathData,'lat', 'Dimensions',{'lat' length(lat(:))}, ...
        'Format',strFormat, 'Datatype', 'double');
    nccreate(pathData,'lon','Dimensions',{'lon' length(lon(:))}, ...
        'Format',strFormat, 'Datatype', 'double'); 
else
    %Find current number of datapoints in NetCDF file:
    infoData = ncinfo(pathData, char(var));
    strtData = infoData.Size;
    
    infoTime = ncinfo(pathData, 'time');
    strtTime = infoTime.Size;
    
    strtTime = strtTime + 1;
    strtData = [strtData(1) + 1, 1, 1];
%     strtData = [strtData(1) + ones(numel(size(data)),1)];
end


switch numel(dateVec(1,:))
    case 1
        refDate = [1900,1,1];
    case 2
        refDate = [1900,1,1];
    case 3
        refDate = [1900,1,1];
    case 4
        refDate = [1900,1,1,0];
    otherwise
        error('print_grid_NC:timeVec',[num2str(numel(dateVec(1,:))) ...
            ' is an unexpected number of elements in the time vector.']);
end


attData = {'missing_value', filVal};
if ~isnan(units)
    attData(2,:) = {'units', units};
end

attTime = {'units', 'days since 1900-01-01'; ...
    'calendar', 'gregorian'; ...
    'bounds', 'time_bnds'; ...
    'axis', 'T'; ...
    'long_name', 'time'; ...
    'standard_name', 'time' ...
    };

if numel(refDate) == 4
    attTime{1,2} = 'days since 1900-01-01-0';
end

attLon = {'units', 'degrees_east'; ...
    'axis', 'X'; ...
    'long_name', 'longitude'; ...
    'standard_name', 'longitude'};

attLat = {'units', 'degrees_north'; ...
    'axis', 'Y'; ...
    'long_name', 'latitude'; ...
    'standard_name', 'latitude' ...
    };

%Only write attributes if file is new:
if strtTime == 1
    %Write global attributes:
    info = {'Created in','print_grid_NC_v2 written by Thomas Mosier'; ...
            'Created on', datestr(datetime('now','Format','d-MMM-y'))};
    for ii = 1 : length(info(:,1))
        ncwriteatt(pathData,'/',info{ii,1},info{ii,2}) %'/' indicates global attribute
    end

    %Write time variable attributes:
    for ii = 1 : length(attTime(:,1))
        ncwriteatt(pathData,'time',attTime{ii,1},attTime{ii,2})
    end

    %Write latitude variable attributes:
    for ii = 1 : length(attLat(:,1))
        ncwriteatt(pathData,'lat',attLat{ii,1},attLat{ii,2})
    end

    %Write longitude variable attributes:
    for ii = 1 : length(attLon(:,1))
        ncwriteatt(pathData,'lon',attLon{ii,1},attLon{ii,2})
    end
% 
%     %Write data variable attributes:
%     %Remove '_FillValue' (it's written above) from data attributes
%     indFil = nan;
%     for ii = 1 : length(attData)
%         if ~isempty(regexpi(attData{ii,1},'fill'))
%            indFil = ii; 
%         end
%     end

%     if ~isnan(indFil)
%         attData(indFil,:) = [];
%     end


    %Write data attributes:
    for ii = 1 : length(attData(:,1))
        ncwriteatt(pathData,char(var),attData{ii,1},attData{ii,2}) %'/' indicates global attribute
    end
end


timeDays = days_since(refDate, dateVec, 'gregorian');
timeBndsDays = days_since(refDate, dateBnds, 'gregorian');

%Check if time elements are nan:
if sum(isnan(timeDays)) > 0
   warning('printGridNc:nanTime',[' NaN time '...
       'values have been detected.  This may cause the program to crash.']); 
end

%Change NaN data to fill value:
% data( isnan(data) ) = filVal;

%%Create and write variables to NetCDF file:
%Write time vector:
ncwrite(pathData,'time', timeDays, strtTime);
%Create time bounds to write:
if all(size(timeBndsDays) == size(timeDays)) && all(timeBndsDays == timeDays)
    timeBndsDaysWrt = [timeBndsDays(:)'; timeBndsDays(:)'];
%     timeBndsDaysWrt = [timeBndsDays(:)'; timeBndsDays(:)' + 0.9999];
elseif numel(timeBndsDays) == 2*numel(timeDays)
    szTBnds = size(timeBndsDays);
    if szTBnds(1) == 2
        timeBndsDaysWrt = timeBndsDays;
    elseif szTBnds(2) == 2
        timeBndsDaysWrt = timeBndsDays';
    elseif any(szTBnds == 2*numel(timeDays)) && any(szTBnds == 1)
        timeBndsDaysWrt = nan(2, numel(timeDays));
        cntr = 0;
        for ll = 1 : numel(timeDays)
            timeBndsDaysWrt(:,ll) = timeBndsDays(cntr+1:cntr+2);
            cntr = cntr+2;
        end
    end
elseif numel(timeBndsDays) == numel(timeDays) + 1
    %Rearrange timeBnds:
    timeBndsDaysWrt = [timeBndsDays(1:numel(timeDays)), timeBndsDays(2:numel(timeDays)+1)]';
elseif all(isnan(timeBndsDays)) && all(isnan(timeDays)) 
    timeBndsDaysWrt = [timeBndsDays(:)'; timeBndsDays(:)'];
else
    error('printGridNc:unknownTimeBnds','The dimensions or values of time bounds are not recognized.')
end

%Write time bounds:
ncwrite(pathData,'time_bnds', timeBndsDaysWrt, [1, strtTime]); 

    
%Only write lat and lon variables if file is new:
if strtTime == 1
    %Latitude:
    ncwrite(pathData,'lat',lat);
    
    %Longitude:
    ncwrite(pathData,'lon',lon);
end

%Data needs to have 3 indices (if has 2, add 1)
if length(size(data)) == 2
    dataTemp = nan([1,size(data)]);
    dataTemp(1,:,:) = data;
    data = dataTemp;
end

%Convert precision:
prec(prec < 0) = 0;
data = round2(data, prec);

%Convert any NaN's to filVal
data(isnan(data)) = filVal;

%Write Data:
if regexpbl(dataTyp,'uint16')
    data = uint16(data);
elseif regexpbl(dataTyp,'int16')
    data = int16(data);
elseif regexpbl(dataTyp,'single')
    data = single(data);
end


ncwrite(pathData, char(var), data, strtData, [1,1,1]);