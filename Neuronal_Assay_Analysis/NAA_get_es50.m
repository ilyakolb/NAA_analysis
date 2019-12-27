function es50=NAA_get_es50(resp,nAP)
[nAP,ind]=sort(nAP);
resp=resp(ind);
[M,idx]=max(resp);
resp=resp/M;
ind=find(resp(1:idx)<0.5);
if isempty(ind)
    ind=1;
end
ind=ind(end);
es50=interp1(resp(ind:(ind+1)),nAP(ind:(ind+1)),0.5,'linear');