clc;

% Define some parameters
path            = 'img/im8s.jpg';   % Path to image being processed
angleSpan       = 5;                % Minimum/maximum image rotation to correct
angleDelta      = 0.05;             % Image rotation correction step size
showStaffRanges = false;             % Toggle debug drawing of staff ranges
showNotes       = true;             % Toggle debug drawing of notes

% Load and invert the image
RGB = imcomplement(imread(path));
% Get the pixel width, height and number of channels
[height, width, channels] = size(RGB);
% Convert to grayscale (also rotate)
gray = rgb2gray(imrotate(RGB, 90, 'bicubic'));
% Calculate optimal threshold
thres = graythresh(gray);
% Binarize the image
BW = imbinarize(gray, thres);
% Calculate the Hough transform of the image
[H, T, R] = hough(BW, 'Theta', -angleSpan:angleDelta:angleSpan);

% Get the strongest line
% First column is rho index, second is theta index
P = houghpeaks(H, 1);
% Find out how much it needs to rotate
thetaPeak = T(P(1, 2));

% Straighten the ORIGINAL image
RGB = imrotate(RGB, thetaPeak, 'bicubic');
% Recalculate size
[height, width, channels] = size(RGB);
% imshow(RGB);

% Convert to grayscale
gray = rgb2gray(RGB);
% Calculate optimal threshold
thres = graythresh(gray);
% Binarize the image
BW = imbinarize(gray, thres);

% Get the staff line profile
[staffLines, staffRows, rowHeight] = StaffProfile(BW);

% Stretch the result and show it
% imshow(repmat(staffLines, 1, width));

% Show staff row ranges
imshow(~BW);
%imshow(ones(height, width));
hold on

% Morphological filter matrix used to detect notes
% How accurate the note detection is depends on how well
% this filter matches the shape of the notes on the sheet

noteShape = [
    0 0 1 1 1 0 0;
    0 1 1 1 1 1 0
    1 1 1 1 1 1 1
    1 1 1 1 1 1 1
    1 1 1 1 1 1 1
    0 1 1 1 1 1 0
    0 0 1 1 1 0 0];

% Identify and get the notes from the black-and-white image
[notesBB, notes] = GetNotes(BW, noteShape);
%
% Notes are stored in a row matrix, like this:
% [x, y] % Note 1
% [x, y] % Note 2
% [x, y] % Note 3
% [x, y] % Note 4
% ...
% They are sorted based on their x-coordinates

indices = ones(1, length(staffRows));

% Construct the hook map
% Close small gaps
hookMap = BW;
hookMap = imclose(hookMap, ones(2, 2));
% Remove staff lines
hookMap = imopen(hookMap, [0 1 0; 0 1 0; 0 1 0]);
% Find horizontal lines (hooks)
hookMap = imopen(hookMap, ones(2, 16));
hookMap = imdilate(hookMap, ones(5, 5));

% Project each hook map row vertically
for row = staffRows
    top = round(row - rowHeight * 1.35);
    bot = round(row + rowHeight * 1.35);
    proj = hookMap;
    proj(1:top, :) = 0;
    proj(bot:length(proj), :) = 0;
    % Project the hook map vertically
    proj = mean(proj) > 0;
    % 
    proj = repmat(proj', 1, height)';
    % 
    hookMap(top:bot, :) = proj(top:bot, :);
end

% img = ones(height, width, 3);
% img(:,:,2) = ~hookMap;
% img(:,:,3) = ~hookMap;
% 
% imshow(img);
%imshow(ones(height, width));
%hold off
%
if showStaffRanges == true
    for row = staffRows
        
        % Row center
        plot([1, width], [row row], 'black');
        % Row edges
        plot([1, width], [row+rowHeight/2 row+rowHeight/2], 'black');
        plot([1, width], [row+rowHeight/4 row+rowHeight/4], 'black');
        plot([1, width], [row-rowHeight/2 row-rowHeight/2], 'black');
        plot([1, width], [row-rowHeight/4 row-rowHeight/4], 'black');
    end
end

for row=1:size(notes,1)
    % Note coordinates
    x = notes(row, 1);
    y = notes(row, 2);
    
    % Get the note profile
    [staffRow, key] = NoteProfile(hookMap, x, y, staffRows, rowHeight);
    
    if ~ismissing(key)
        % Set the key
        keys(staffRow, indices(1, staffRow)) = key;
        % Increment index for the current staff row
        indices(1, staffRow) = indices(1, staffRow)+1;

        if showNotes == true
            % Plot line
            % plot([x, x], [staffRows(staffRow) y], 'red');
            % Plot note
            plot(x, y, 'ko', 'MarkerFaceColor', 'k');
        end
        
        text(x, staffRows(staffRow) - rowHeight, key, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    end
end

hold off

% Output to file
fileID = fopen('output.txt','w');

for row=1:size(keys, 1)
    for col=1:size(keys, 2)
        if ~ismissing(keys(row, col))
            fprintf(fileID, keys(row, col));
            fprintf(fileID, ' ');
        end
    end
    fprintf(fileID, '\n');
end

fclose(fileID);