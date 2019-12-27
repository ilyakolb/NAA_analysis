function res = cstrcmp(x, y)
% res = cstrcmp(x, y) gives the results of the comparison. 
% "res" is zero if the strings are identical.
% "res" is positive if string "x" is greater than string "y",  
% and is negative if string "y" is greater than string "x".  
% Comparisons of are made according to the ASCII values. 
res = 0;
if(iscellstr(x))
    x = char(x);
end
if(iscellstr(y))
    y = char(y);
end
if(~ischar(x) || ~ischar(y))
    error('Input must be character arrays');
end
lenx = length(x);
leny = length(y);
strLen = min(lenx, leny);
i = find( x(1 : strLen)~= y(1 : strLen), 1);
if(~isempty(i))
    res = double(x(i)) - double(y(i));
end
if(res == 0 && (lenx ~= leny))
    if(strLen == lenx)
        res = -(double(y(strLen + 1)));
    else
        res = -(double(x(strLen + 1)));
    end
end
