function plot_ts_ci(sPlot, clLgd, varargin)

%Time-series are input as set of 3 arrays:
%(1) y-data (n by 1)
%(2) confidence intervals (n by 2)
%(3) x-data (n by 1)

if ischar(clLgd)
    clLgd = {clLgd};
end


nTs = numel(clLgd);

refLn = [];
tsClr = [];
path = [];
yLab = [];
xLab = [];
ciType = 'err';
lineSpec = [];
MarkerFaceColor = [];
MarkerEdgeColor = [];
xLm = nan(1,2);
yLm = nan(1,2);
lblXTick = [];
locLgd = 'northwest';
wrtFormat = {'png', 'tiff', 'eps', 'fig'};
if numel(varargin(:)) > nTs*3
    for ii = nTs*3 + 1 : numel(varargin(:))
        if strcmpi(varargin{ii}, 'refline')
            refLn = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'color')
            tsClr = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'path')
           path = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'ylab')
            yLab = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'xlab')
            xLab = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'xticklabel')
            lblXTick = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'citype')
            ciType = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'linespec')
            lineSpec = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'MarkerFaceColor')
            MarkerFaceColor = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'MarkerEdgeColor')
            MarkerEdgeColor = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'xlim')
            xLm = varargin{ii+1};
        elseif strcmpi(varargin{ii}, 'ylim')
            yLm = varargin{ii+1};
        elseif regexpbl(varargin{ii}, {'legend','loc'}, 'and')  
            locLgd = varargin{ii+1};
        elseif regexpbl(varargin{ii}, {'write', 'format'}, 'and')  
            wrtFormat = varargin{ii+1};
        end
    end
end

if isempty(tsClr)
    tsClr = distinguishable_colors(nTs);
else
    if numel(tsClr(:,1)) ~= nTs 
        error('plotTsCi:clrNumber','The number of colors provided does not match the number of time-series detected.')
    end
end

xMn = 10^6;
xMx = -10^6;
yMn = 10^6;
yMx = -10^6;

%Create figure
hFig = figure('Units','in','Position',[2 2 sPlot.sz], 'paperunits','in','paperposition',[2 2 sPlot.sz], 'color', 'white', 'visible', sPlot.vis, 'AlphaMap', 1);
% set(0,'defaultfigurecolor',[1 1 1])
% whitebg([1,1,1]);
set(gcf,'color','w');
hold on

%Plot confidence intervals first:
hCI = nan(nTs, 1);
for ii = 1 : nTs
    if ~isempty(varargin{2+3*(ii-1)})
        if strcmpi(ciType, 'err')
            ciCurr = varargin{2+3*(ii-1)} + repmat(varargin{1+3*(ii-1)}, [1,2]);
        elseif strcmpi(ciType, 'abs')
            ciCurr = varargin{2+3*(ii-1)};
        else
            error('plotTsCi:unknownCiType',['The confidence interval type ' ciType ' is unknwown.']);
        end
        
        
        hCI(ii) = ciplot(ciCurr(:,1), ciCurr(:,2), varargin{3+3*(ii-1)}, tsClr(ii,:));
        
        alpha(hCI(ii), 0.2);
        
        yMn = min(yMn, min(ciCurr(:,1)));
        yMx = max(yMx, max(ciCurr(:,2)));
    end
end

hCI(isnan(hCI)) = [];

if ~isempty(lineSpec)
    if ~iscell(lineSpec)
        lineSpec = {lineSpec};
    end
    
    if numel(lineSpec) == 1
        lineSpec = repmat(lineSpec, nTs, 1);
    elseif ~numel(lineSpec) == nTs
        error('plotTsCi:nLineSpec', ['The line specification has ' num2str(numel(lineSpec)) ' entries, but there are ' num2str(nTs) ' lines to plot.'])
    end
end

%Plot mean projection lines:
hTs = nan(nTs,1);
for ii = 1 : nTs
    yCurr = varargin{1+3*(ii-1)};
    xCurr = varargin{3+3*(ii-1)};
    
    if isempty(xCurr)
        xCurr = nan;
        yCurr = nan;
    end
    
    if ~isempty(lineSpec)
        hTs(ii) = plot(xCurr, yCurr, lineSpec{ii}, 'color', tsClr(ii,:), 'LineWidth', sPlot.lnwd);
    else
        hTs(ii) = plot(xCurr, yCurr,'color', tsClr(ii,:), 'LineWidth', sPlot.lnwd);
    end
    
    if ~isempty(MarkerFaceColor)
        if strcmpi(MarkerFaceColor, 'filled')
            set(hTs(ii), 'MarkerFaceColor', tsClr(ii,:));
        else
            set(hTs(ii), 'MarkerFaceColor', MarkerFaceColor);
        end
    end
    
    if ~isempty(MarkerEdgeColor)
        if isprop(hTs(ii), 'MarkerEdgeColor')
            if strcmpi(MarkerEdgeColor, 'same')
                set(hTs(ii), 'MarkerEdgeColor', tsClr(ii,:));
            else
                set(hTs(ii), 'MarkerEdgeColor', MarkerEdgeColor);
            end
        end
    end
    
    
    yMn = min(yMn, nanmin(yCurr));
    yMx = max(yMx, nanmax(yCurr));
    
    xMn = min(xMn, nanmin(xCurr(~isnan(yCurr))));
    xMx = max(xMx, nanmax(xCurr(~isnan(yCurr))));
end

if ~isempty(refLn)
    hLine = line(refLn(1:2), refLn(3:4));
    refGray = [0.5,0.5,0.5];
    
    set(hLine,'LineWidth', sPlot.lnwd, ...
        'color', refGray, 'LineStyle','--');
end

hold off

%Check to see if there are legend entries for all inputs:
hLgd = [];
if numel(clLgd(:)) == numel(hTs(:))
    hTsLgd = hTs;
    for ii = numel(hTs(:)) : -1 : 1
        if isempty(clLgd{ii})
            clLgd(ii) = [];
            hTsLgd(ii) = [];
        end
    end
    
    if ~isempty(hTsLgd)
        hLgd = legend(hTsLgd, clLgd, 'Location', locLgd);
    end
else
    warning('plotTsCi:diffNumTsLgd',['There are ' num2str(numel(hTs(:))) ...
        ' time-series and ' num2str(numel(clLgd(:))) ' legend entries. '...
        'A legend is not being produced because the numbers do not match.']);
end

if isfield(sPlot, 'ylabel')
    hYLab = ylabel(sPlot.ylabel);

    set(hYLab, ...
    'FontName'   , sPlot.font, ...
    'FontSize'   , ftSzT, ...
    'Color', 'black');
end
if isfield(sPlot, 'xlabel')
    hXLab = xlabel(sPlot.xlabel);

    set(hXLab, ...
    'FontName'   , sPlot.font, ...
    'FontSize'   , ftSzT, ...
    'Color', 'black');
end

%Set x-tick labels
if ~isempty(lblXTick)
    xTicks = get(gca,'XTick');

    if numel(xTicks) == numel(lblXTick)
        set(gca,'XTickLabel', lblXTick);
    else
        warning('plotTsCi:differentTickLenth', ['The x-ticks are being '...
            'adjusted in order to set the requested x-tick labels '...
            'because they currently have different lengths. This may '...
            'impact placement.']);
    	set(gca, 'XTick', linspace(xTicks(1), xTicks(end), numel(lblXTick)));
        set(gca,'XTickLabel', lblXTick);
    end
end

yRng = yMx - yMn;
if yRng  < 1
    yScl = 1.01;
elseif yRng  < 10
    yScl = 1.07;
elseif yRng < 20
    yScl = 1.07;
elseif yRng  < 30
    yScl = 1.09;
elseif yRng  < 40
    yScl = 1.09;
else
    yScl = 1.1;
end

if xMx > xMn
    xLmUse = [xMn, xMx];
    
    if any(~isnan(xLm))
        if ~isnan(xLm(1))
            xLmUse(1) = xLm(1);
        end
        if ~isnan(xLm(2))
            xLmUse(2) = xLm(2);
        end
    end
    
    xlim(xLmUse);
elseif isnan(xMn) || isnan(xMx)
    return
end
if yMx > yMn
    if yMn < 0
        yMnLm = (yScl-0.8*abs(1-yScl))*yMn;
    else
        yMnLm = abs(2-yScl)*yMn;
    end
    if yMx < 0
        yMxLm = abs(2-yScl)*yMx;
    else
        yMxLm = yScl*yMx;
    end
    
    yLmUse = [yMnLm, yMxLm];
    if any(~isnan(yLm))
        if ~isnan(yLm(1))
            yLmUse(1) = yLm(1);
        end
        if ~isnan(yLm(2))
            yLmUse(2) = yLm(2);
        end
    end
    ylim(yLmUse);
elseif isnan(yMn) || isnan(yMx)
    return
end


if ~isempty(yLab)
    hYLab = ylabel(yLab);
else
    hYLab = [];
end
if ~isempty(xLab)
    hXLab = xlabel(xLab);
else
    hXLab = [];
end

% for kk = 1 : nSce
%     if kk == 1
%         clrLn = custGrn;
%     elseif kk == 2
%         clrLn = custPrp;
%     end
%     set(hCntryProj(kk),'LineWidth',lnWd, ...
%         'Color',clrLn, ...
%         'linestyle','--');
%     set(hCntryProj(kk),'LineWidth',lnWd, ...
%         'Color',clrLn, ...
%         'linestyle','--');
% end
%Set figure properties:
set(hTs, ...
    'LineWidth', sPlot.lnwd);
if ~isempty(hCI)
    set(hCI,...
        'linestyle', 'none');
end
if ~isempty(hLgd)
    set(hLgd, ...
        'FontSize'   , sPlot.ftsz, ...
        'LineWidth', sPlot.axlnwd);
end
if ~isempty(xLab)
    set(hXLab, ...
        'FontSize'   , sPlot.ftsz, ...
        'LineWidth', sPlot.axlnwd);
end
if ~isempty(yLab)
    set(hYLab, ...
        'FontSize'   , sPlot.ftsz, ...
        'LineWidth', sPlot.axlnwd);
end
set(gca, ...
    'Box'         , 'off', ...
    'TickDir'     , 'out'     , ...
    'TickLength'  , [.02 .02] , ...
    'YMinorTick'  , 'on'      , ...
    'fontSize'    , sPlot.axfntsz, ...
    'LineWidth'   , sPlot.axlnwd, ...
    'FontName'   , sPlot.font);

if ~isempty(path)
    for ii = 1 : numel(wrtFormat)
        if exist([path, '.' wrtFormat{ii}], 'file')
            delete([path, '.' wrtFormat{ii}])
        end
        if strcmpi(wrtFormat{ii}, 'fig')
            savefig(hFig, [path '.fig']);
        else
        	export_fig([path '.' wrtFormat{ii}], ['-' wrtFormat{ii}], sPlot.res);
        end
    end
end
