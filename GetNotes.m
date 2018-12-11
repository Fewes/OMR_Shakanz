function [notes, NotePosMat] = GetNotes(BW, noteShape)

% Close small gaps in the image;
BW2 = imclose(BW, ones(2, 2));

% Remove staff lines
BW2 = imopen(BW, [0 1 0; 0 1 0; 0 1 0]);

% Remove horizontal lines
%BW2 = imerode(BW2, ones(1, 12));
%BW2 = imdilate(BW2, ones(5, 5));
BW2 = BW2 .* ~imerode(BW2, ones(1, 16));

% Remove vertical lines
BW2 = imopen(BW2, [0 0 0; 1 1 1; 0 0 0]);

% Isolate notes using the note shape kernel
BW2 = imopen(BW2, noteShape);

%noteShape = [0 1 0; 0 1 0; 0 1 0];
%BWithoutlines = imerode(BWithoutlines, noteShape);

%BWithoutlines = imerode(BWithoutlines, noteShape);
%BWithoutlines = imdilate(BWithoutlines, noteShape);
%BWithoutlines = imdilate(BWithoutlines, noteShape);

%BWithoutlines = imopen(BWithoutlines, noteShape);
%BWithoutlines = bwmorph(BWithoutlines, 'fill');
%BWithoutlines = imerode(BWithoutlines, ones(1, 16));

%imshow(BW2);

L = bwlabel(BW2);
BoundingBoxes = regionprops(L, 'BoundingBox');
notes = BoundingBoxes;
CoF = regionprops(L, 'Centroid');
notePositions = extractfield(CoF, 'Centroid');
notePosX = notePositions(1:2:end)';
notePosY = notePositions(2:2:end)';
NotePosMat = [notePosX, notePosY];

% for k = 1 : length(BoundingBoxes)
%   thisBB = BoundingBoxes(k).BoundingBox;
%   rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],...
%   'EdgeColor','g','LineWidth',2 );
% end

%%

% BW = bwmorph(BW,'erode',1);
% 
% L = bwlabel(BW);
% 
% BoundingBoxStat = regionprops(L, 'BoundingBox');
% EulerNumberStat = regionprops(L, 'EulerNumber');
% CoF = regionprops(L, 'Centroid');
% 
% imshow(L);
% hold on
% 
% 
% for k = 1 : length(BoundingBoxStat)
%   thisBB = BoundingBoxStat(k).BoundingBox;
%   rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],...
%   'EdgeColor','g','LineWidth',2 );
% end
