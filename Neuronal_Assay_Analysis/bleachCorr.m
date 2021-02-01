function [y_detrended] = bleachCorr(t,y, indicesForFit)
%BLEACHCORR bleach correction with double exponential
%   inputs:
%          t: time vector
%          y: y vector
%          indicesForFit: vector of indices to use for fit (usually [10:150
%          1000:1399] (beginning and end)

% y_detrended = detrend(y, 1);
% make sure both t and y are column vectors
if size(t, 1) == 1
    t = t';
end


yToFit = y(indicesForFit);
tToFit = t(indicesForFit);

[fitresult, ~] = createFitDoubleExp(tToFit, yToFit);
yFit = feval(fitresult, t);
% hold on, plot(t, yFit, 'k-')

y_detrended = y - yFit;
% figure, plot(t, y_detrended)

end

