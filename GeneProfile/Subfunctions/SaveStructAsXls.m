function SaveStructAsXls(Matrix,SaveFile,Names)

%Names=fieldnames(FitProfile)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Opens an excel file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Excel = actxserver('Excel.Application');

Excel.Visible = false;
Workbook = Excel.Workbooks.Add;
NFiles=size(Matrix,2);

NColumns=size(Names,1);
Excel.Cells.ColumnWidth = 160/NColumns;

for nn=NFiles:-1:1
    Matrix2=struct2cell(Matrix(nn));
    Excel.Sheets.Add;
    Excel.ActiveSheet.set('Name',strcat('Sample_',num2str(nn)));
    for jj=1:NColumns
        Excel.ActiveSheet.get('Cells', 1, jj).Value=Names{jj};
        NLines=length(Matrix2{jj});
        for ii=2:NLines+1
            Excel.ActiveSheet.get('Cells', ii, jj).Value=Matrix2{jj}(ii-1);
        end
        
    end
    
end


Workbook.SaveAs(SaveFile);

Workbook.Close;

Excel.Quit;

delete(Excel)


end