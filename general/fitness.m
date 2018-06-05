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

function statOut = fitness(obs, mod, strEval, varargin)


%Score for fitness metric evaluation that returns 0. 
nanPen = 10^3;

% if isempty(obs) || isempty(mod)
%     if iscell(strEval)
%         statsOut = nan(size(strEval(:)));
%     else
%         statsOut = nan;
%     end
% 
%     return
% end

obs = squeeze(obs);
mod = squeeze(mod);

if numel(size(mod)) == 2
    %Ensure observed and modelled vectors have same orientation (probably
    %doesn't matter):
    if numel(obs(1,:)) == 1 && numel(obs(:,1)) ~= 1
       obs = obs'; 
    end
    if numel(mod(1,:)) == 1 && numel(mod(:,1)) ~= 1
       mod = mod'; 
    end
    
%     %Remove values based on nan's in observed vector:
%     mod(isnan(obs)) = [];
%     obs(isnan(obs)) = [];

    %If optional input, remove values based on nan's in modeled vector:
    if ~isempty(varargin(:)) && regexpbl(varargin{1},'rmMod')
        obs(isnan(mod)) = [];
        mod(isnan(mod)) = [];
    end
end

if ischar(strEval)
   strEval = {strEval}; 
end

nFit = numel(strEval(:));
statOut = nan(nFit, 1);
for mm = 1 : nFit
    
%     %Can have two evaluation methods, one = MODIS (only for 3D arrays) and
%     %second for all other cases:
%     if regexpbl(strEval{mm},'Parajka')
%         if numel(size(mod)) == 3 
%             strEval{mm} = 'Parajka';
%         elseif numel(size(mod)) == 2
%             indMOD = regexpi(strEval{mm},'Parajka');
%             strEval{mm}(indMOD:indMOD+4) = []; 
%         end
%     end

    if ~isequal(size(obs),size(mod))
       warning('fitness:unequalSize',['The model output and observations '...
           'to be compared have different sizes and are therefore not being compared.']); 
       statOut(mm) = nan;
       return
    end

    % %Make obserseved the same size as modelled so subtraction/add work.
    % if ~isequal(size(obs),size(mod))
    %     obs = obs(ones(size(mod,1),1),:);
    % end

    if regexpbl(strEval{mm},'bias') %BIAS:
        statOut(mm) = nanmean(obs(:) - mod(:));
    elseif regexpbl(strEval{mm},'RMSE') %ROOT MEAN SQUARE ERROR:
        statOut(mm) = sqrt(nanmean((mod(:) - obs(:)).^2));
    elseif regexpbl(strEval{mm},'abs') %MINIMIZE ABSOLUTE DIFFERENCE:
        statOut(mm) = sqrt(nansum((obs(:) - mod(:)).^2 , 2));
    elseif regexpbl(strEval{mm},{'MAE','mean absolute error'})
        statOut(mm) = nanmean( abs(mod(:) - obs(:)));
    elseif regexpbl(strEval{mm},'mape') && ~regexpbl(strEval{mm},'wmape') %MINIMIZE MEAN ABSOLUTE PERCENT ERROR:
        indRem = find(obs == 0);
        indRem = union(indRem, find(isnan(obs)));
        indRem = union(indRem, find(isnan(mod)));
        obs(indRem) = [];
        mod(indRem) = [];

        if regexpbl(strEval{mm},'agg')
            statOut(mm) = abs(nanmean(mod(:) - obs(:)))./abs(nanmean(obs(:)));
        else
            statOut(mm) = nanmean( abs((mod(:) - obs(:))./abs(obs(:))));
        end
    elseif regexpbl(strEval{mm},'wmape') %MINIMIZE WEIGHTED MEAN ABSOLUTE PERCENT ERROR:
        indRem = find(obs == 0);
        indRem = union(indRem, find(isnan(obs)));
        indRem = union(indRem, find(isnan(mod)));
        obs(indRem) = [];
        mod(indRem) = [];
        statOut(mm) = nansum( abs(obs(:)).*abs((mod(:) - obs(:))./obs(:))) / nansum(obs(~isnan(obs) & ~isnan(mod)));
    elseif regexpbl(strEval{mm},'pearson')
         %[r,p] = corrcoef(squeeze(obs(indUse,jj,ii)), squeeze(mod(indUse,jj,ii)));
        corr = corrcoef(obs(:), mod(:));
        statOut(mm) = corr(2);

        if  nFit == 1
            statOut(2) = corr(1);
        end
    elseif regexpbl(strEval{mm}, 'mbe') %mass balance efficiency
        %The 'mbe' (mass balance efficiency) is a statistic of a similar
        %form as the KGE (Kling Gupta Efficiency), adapted to assess model
        %performance of gridded glacier mass balance modelling over a region
        %The 'rTerm' assesses error in the spatial pattern (first using a smoothing filter)
        %The 'bTerm' assesses error in the regional bias

        %Apply Gaussian filter for calculating correlation
        rad = 2;
        sigma = rad;
        obsGauss = Gaussian_filter(obs, rad, sigma);
        obsGauss(isnan(obs)) = nan;
        
        modGauss = Gaussian_filter(mod, rad, sigma);
        modGauss(isnan(mod)) = nan;

        %Remove nan values:
        indRem = [];
        indRem = union(indRem, find(isnan(obsGauss)));
        indRem = union(indRem, find(isnan(modGauss)));
        obsGauss(indRem) = [];
        modGauss(indRem) = [];

        covVar = cov(obsGauss,modGauss);
        if numel(covVar) > 1
            rTerm = (covVar(2)/(nanstd(obsGauss)*nanstd(modGauss))-1)^2;
%             rTerm = nanmean(abs(mod-obs))/nanstd(obs);
%             R = (corrcoef(obs,mod) - 1)^2;
%             [~, valMod] = e_cdf(mod, 'bins', 100);
%             [~, valObs] = e_cdf(obs, 'bins', 100);
%             
%             sTerm = (nanmean(abs((valMod(2:end)-valObs(2:end)))./nanmean(valObs(2:end))))^2;
%             
%             sTerm = (nanmean(abs((valMod(2:end)-valObs(2:end))./valObs(2:end))))^2;
% %             sTerm = (nanstd(mod)/nanstd(obs)-1)^2;
        else
            rTerm = nan;
        end
        
        bTerm = ((nanmean(mod(:))-nanmean(obs(:)))/nanstd(obs(:)))^2;
        %See definition of the KGE and linear correlation coefficient (can be decomposed into covariance and SD)
        statOut(mm) = sqrt(rTerm + bTerm);
    elseif regexpbl(strEval{mm},'NSE') || regexpbl(strEval{mm},{'nash','sutcliffe'},'and')%MINIMIZE USING NASH-SUTCLIFFE EFFICIENCY:
        if ndims(mod) == 3
            %Calculate the NSE score over time at each grid location, then average
            %over domain
            nFitG = nan(size(squeeze(mod(1,:,:))));
            for jj = 1 : numel(nFitG(:,1))
                for ii = 1 : numel(nFitG(1,:))
                    indUse = intersect(find(~isnan(squeeze(obs(:,jj,ii)))), find(~isnan(squeeze(mod(:,jj,ii)))));

                    if ~isempty(indUse)
                        denomNse = nansum( (squeeze(obs(indUse,jj,ii)) - nanmean(squeeze(obs(indUse,jj,ii))).*ones(numel(squeeze(obs(indUse,jj,ii))),1)).^2);
                        nFitG(jj,ii) = nansum((squeeze(obs(indUse,jj,ii)) - squeeze(mod(indUse,jj,ii))).^2) ...
                            ./ denomNse;
                        if denomNse == 0
                            nFitG(jj,ii) = nan;
                        end 
                    else
                        nFitG(jj,ii) = nan;
                    end
                end
            end

            statOut(mm) = mean2d(nFitG);
        elseif numel(size(mod)) == 2
            %Remove nan values:
            indRem = [];
            indRem = union(indRem, find(isnan(obs)));
            indRem = union(indRem, find(isnan(mod)));
            obs(indRem) = [];
            mod(indRem) = [];
            
            denomNse = nansum( (obs - nanmean(obs,2)*ones(1, numel(obs(1,:)))).^2, 2);
            statOut(mm) = nansum((obs - mod).^2, 2) ...
                ./ denomNse;
            if denomNse == 0
                statOut(mm) = nan;
            end 
        end
    elseif regexpbl(strEval{mm},'KGE') || regexpbl(strEval{mm},{'kling','gupta'},'and')        
            %See definition of the KGE and linear correlation coefficient (can be decomposed into covariance and SD)
            %     nFit(mm) = sqrt((corrcoef(2)-1)^2 + (nanstd(mod)/nanstd(obs)-1)^2 + (nanmean(mod)/nanmean(obs)-1)^2);
        if numel(size(mod)) == 3
            %Calculate the KGE score over time at each grid location, then average
            %over domain
            nFitG = nan(size(squeeze(mod(1,:,:))));
            for jj = 1 : numel(mod(1,:,1))
                for ii = 1 : numel(mod(1,1,:))
                    indUse = find(~isnan(squeeze(obs(:,jj,ii))) & ~isnan(squeeze(mod(:,jj,ii))));

                    if ~isempty(indUse)
                        %[r,p] = corrcoef(squeeze(obs(indUse,jj,ii)), squeeze(mod(indUse,jj,ii)));
                        covVar = cov(squeeze(obs(indUse,jj,ii)), squeeze(mod(indUse,jj,ii)));
                        if numel(covVar) > 1
                            rTerm = (covVar(2)/(nanstd(squeeze(obs(indUse,jj,ii)))*nanstd(squeeze(mod(indUse,jj,ii))))-1)^2;
                        else 
                            rTerm = nan;
                        end
                        
                        sTerm = (nanstd(squeeze(mod(indUse,jj,ii)))/nanstd(squeeze(obs(indUse,jj,ii)))-1)^2;
                        bTerm = (nanmean(squeeze(mod(indUse,jj,ii)))/nanmean(squeeze(obs(indUse,jj,ii)))-1)^2;
                        
                        if regexpbl(strEval{mm},'KGEr') %r correlation term: 
                            nFitG(jj,ii) = sqrt(rTerm);
                        elseif regexpbl(strEval{mm},'KGEs') %standard deviation term
                            nFitG(jj,ii) = sqrt(sTerm);
                        elseif regexpbl(strEval{mm},'KGEb') %Bias term
                            nFitG(jj,ii) = sqrt(bTerm);
                        else
                            nFitG(jj,ii) = sqrt(rTerm + sTerm + bTerm);
                        end
                    else
                        nFitG(jj,ii) = nan;
                    end
                end
            end

            statOut(mm) = mean2d(nFitG);
        elseif numel(size(mod)) == 2
            %Remove nan values:
            indRem = [];
            indRem = union(indRem, find(isnan(obs)));
            indRem = union(indRem, find(isnan(mod)));
            obs(indRem) = [];
            mod(indRem) = [];
        
            covVar = cov(obs,mod);
            if numel(covVar) > 1
                rTerm = (covVar(2)/(nanstd(obs)*nanstd(mod))-1)^2;
            else
                rTerm = nan;
            end
            
            sTerm = (nanstd(mod)/nanstd(obs)-1)^2;
            bTerm = (nanmean(mod)/nanmean(obs)-1)^2;
            
            if regexpbl(strEval{mm},'KGEr') %r correlation term: 
                statOut(mm) = sqrt(rTerm);
            elseif regexpbl(strEval{mm},'KGEs') %standard deviation term
                statOut(mm) = sqrt(sTerm);
            elseif regexpbl(strEval{mm},'KGEb') %Bias term
                statOut(mm) = sqrt(bTerm);
            else
                statOut(mm) = sqrt(rTerm + sTerm + bTerm);
            end
        end
    elseif regexpbl(strEval{mm},{'Parajka','MODIS'})
        %Find number of pixels that are glaciated or have permanent snow cover
        %(i.e. always 100 or nan in MODIS observations)
        szGrid = size(squeeze(obs(1,:,:)));
        subGlac = zeros(prod(szGrid),1, 'single');
        nGlacThresh = 0.01*numel(obs(:,1,1));
        cntr = 1;
        for jj = 1 : numel(obs(1,:,1))
            for ii = 1 : numel(obs(1,1,:))
                if sum2d(~isnan(obs(:,jj,ii)) & obs(:,jj,ii) ~= 100) < nGlacThresh
                    subGlac(cntr) = sub2ind(szGrid, jj, ii);
                    cntr = cntr + 1;
                    
                    mod(:,jj,ii) = nan;
                    obs(:,jj,ii) = nan;
                end
            end
        end
        subGlac(cntr:end) = [];

        %Parajka, J., & Bl�schl, G. (2008). The value of MODIS snow cover data 
        %in validating and calibrating conceptual hydrologic models. Journal of 
        %Hydrology, 358(3?4), 240-258. http://doi.org/10.1016/j.jhydrol.2008.06.006
        
        %Find number of images that are not all nan:
        mCntr = 0;
        for kk = 1 : numel(obs(:,1,1))
            if ~all2d(isnan(squeeze(obs(kk,:,:))))
               mCntr = mCntr + 1; 
            end
        end
        
        lPix = numel(obs(1,:,:)) - numel(subGlac);

        thrshSWE = 10/100; %units = m
        thrshSCA = 10; %units = percent
        wghtOvr = 5; %Weighting factor for over representation
        wghtUnd = 5; %Weighting factor for under representation
        
        EOvr = nan(size(squeeze(obs(1,:,:))));
        EUnd = nan(size(squeeze(obs(1,:,:))));
        for jj = 1 : numel(obs(1,:,1))
            for ii = 1 : numel(obs(1,1,:))
                indCurr = sub2ind(szGrid, jj, ii);
                if ~any(indCurr ==subGlac)
                    indNNan = find(~isnan(mod(:,jj,ii)) & ~isnan(obs(:,jj,ii)));

                    indYObs = find(obs(indNNan,jj,ii) > thrshSCA);
                    indNObs = find(obs(indNNan,jj,ii) == 0);
                    indYMod = find(mod(indNNan,jj,ii) > thrshSWE);
                    indNMod = find(mod(indNNan,jj,ii) == 0);

                    EOvr(jj,ii) = numel(intersect(indYMod, indNObs));
                    EUnd(jj,ii) = numel(intersect(indNMod, indYObs));
                end
            end
        end
        EOvrAvg = sum2d(EOvr)/(mCntr*lPix);
        EUndAvg = sum2d(EUnd)/(mCntr*lPix);

        statOut(mm) = wghtOvr*EOvrAvg + wghtUnd*EUndAvg;

    else
        error('Unkown fitness ranking method specified.');
    end

    if isempty(statOut(mm) )
       statOut(mm) = nan; 
    end

    if isnan(statOut(mm) )
        statOut(mm) = nanPen;
    end
end