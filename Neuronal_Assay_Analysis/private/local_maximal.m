function out=local_maximal(im)

out = colfilt(im,[3 3],'sliding',@max);
out=(out==im);