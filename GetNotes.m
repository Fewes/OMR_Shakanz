function [notes] = GetNotes(BW)


s1 = [0 0 1 0 0; 0 1 1 1 0; 1 1 1 1 1; 0 1 1 1 0 ; 0 0 1 0 0];

BWithoutlines = imerode(BW, s1);
BWithoutlines = imopen(BWithoutlines, s1);
%BWithoutlines = bwmorph(BWithoutlines, 'fill');
imshow(BW);

L = bwlabel(BWithoutlines);
BoundingBoxes = regionprops(L, 'BoundingBox');

for k = 1 : length(BoundingBoxes)
  thisBB = BoundingBoxes(k).BoundingBox;
  rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],...
  'EdgeColor','g','LineWidth',2 );
end


hold off
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
