function [Ima,SizeIma]=OpenTif(FileTif)
Infos=imfinfo(FileTif);
SizeIma.NCol=Infos(1).Width;
SizeIma.NLines=Infos(1).Height;
SizeIma.NImages=numel(Infos);
Ima=zeros(SizeIma.NLines,SizeIma.NCol,SizeIma.NImages);

for ii=1:SizeIma.NImages
    Ima(:,:,ii) = double(imread(FileTif,'Index',ii,'Info', Infos));
end
end