function update_best_zoom(handles);
    global STL;
    
    %nmetavoxels = ceil(STL.print.size ./ (STL.print.bounds - STL.print.metavoxel_overlap));
    overlap_needed = (STL.print.size > STL.print.bounds);
    nmetavoxels = ceil((STL.print.size - STL.print.metavoxel_overlap) ./ (STL.print.bounds - STL.print.metavoxel_overlap.*overlap_needed));
    set(handles.PrinterBounds, 'String', sprintf('Workspace: [ %s] um', ...
        sprintf('%d ', round(STL.print.bounds))));
    set(handles.nMetavoxels, 'String', sprintf('Metavoxels: [ %s]', sprintf('%d ', nmetavoxels)));

    STL.print.zoom_best = floor(min(nmetavoxels(1:2) ./ (STL.print.size(1:2) ./ (STL.bounds_1(1:2)))) * 10)/10;
    
    if all(nmetavoxels(1:2) == 1) & STL.print.zoom_best >= STL.print.zoom_min
        if nargin == 1 & ~isempty(handles)
            set(handles.autozoom, 'String', sprintf('Minimum for print (auto = %g):', STL.print.zoom_best));
        end
    else
        STL.print.zoom_best = STL.print.zoom;
        if nargin == 1 & ~isempty(handles)
            set(handles.autozoom, 'String', 'Minimum for print:');
        end
    end
    
    
end
