
function FilteredIma=Local2DAverage(Ima,BinValue)
FilteredIma=Ima*0;
for ii=0:BinValue-1
    for jj=0:BinValue-1
        FilteredIma=FilteredIma+circshift(circshift(Ima,ii,1),jj,2);
    end
end
FilteredIma=FilteredIma/(BinValue^2);

end