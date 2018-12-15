%%%%%%%%%%%%%%%%%%%%%%%%%%
function strout = tnm034(Im)
%
% Im: Input image of captured sheet music. Imshould be in 
% double format, normalized to the interval [0,1]
%
% strout: The resulting character string of the detected notes.  
% The string must follow the pre-defined format, explained below.
%

% Define some parameters
path                = 'img/im5s.jpg';   % Path to image being processed
angleSpan           = 5;                % Minimum/maximum image rotation to correct
angleDelta          = 0.05;             % Image rotation correction step size
showStaffRanges     = false;            % Toggle debug drawing of staff ranges
showNotes           = false;            % Toggle debug drawing of notes
showHookMap         = false;
underlyingOpacity   = 0.5;              % Show the original sheet music with this opacity

% Load and invert the image
%RGB = imcomplement(imread(path));
RGB = imcomplement(Im);
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

% Remove treble clef
clef = imread('g.png');
[clefHeight, clefWidth, clefChannels] = size(clef);
% Normalized cross correlation
clef = imbinarize(clef(:,:,1));
C = normxcorr2(clef, BW);
% Threshold the result
clefMap = C > 0.3;
% Vertical projection
clefMap = mean(clefMap) > 0.002;
% Shift a bit to the left (the "found" clefs are not centered)
clefMap = circshift(clefMap,-round(clefWidth/2), 2);
% Dilate to cover entire clef
clefMap = imdilate(clefMap, ones(1, clefWidth));
% Get clef ranges
found = 0;
i = 1;
for col = clefMap
    if col && found == 0
        clefStart = i;
        found = 1;
    elseif ~col && found == 1
        clefEnd = i;
        found = -1;
    end
    i = i + 1;
end
% Remove all "clef columns" from the black and white image
BW(:, clefStart:clefEnd) = 0;

% Get the staff line profile
[staffLines, staffRows, rowHeight] = StaffProfile(BW);

% Stretch the result and show it
% imshow(repmat(staffLines, 1, width));

% Show staff row ranges
%imshow(~BW);
%imshow(ones(height, width));
%hold on

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

hookMethod2 = true;
if ~hookMethod2
    % Construct the hook map
    % Close small gaps
    hookMap = BW;
    hookMap = imclose(hookMap, ones(2, 2));
    % Remove staff lines
    hookMap = imopen(hookMap, [0 1 0; 0 1 0; 0 1 0]);
    % Find horizontal lines (hooks)
    hookMap = imopen(hookMap, ones(2, 12));
    hookMap = imdilate(hookMap, ones(5, 5));
else
    hookMap = BW;
    % Close small holes
    hookMap = imclose(hookMap, ones(2, 2));
    % Remove staff lines
    hookMap = imopen(hookMap, [0 1 0; 0 1 0; 0 1 0]);
    % Remove small elements (often residue from thin lines)
    hookMap = imopen(hookMap, ones(4, 4));
    % Remove notes
    hookMap = hookMap - imdilate(imopen(hookMap, noteShape), ones(5, 5));
    % Remove vertical lines
    %hookMap = imopen(hookMap, [0 0 0; 1 1 1; 0 0 0]);
    % Remove small elements
    hookMap = imopen(hookMap, ones(2, 2));
    % Dilate for better note profile accuracy
    hookMap = imdilate(hookMap, ones(6, 6));
end

% Project each hook map row vertically
for row = staffRows
    top = round(row - rowHeight * 1.25);
    bot = round(row + rowHeight * 1.25);
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

% Find horizontal lines (hooks)
%hookMap = imopen(hookMap, ones(2, 12));
%hookMap = imdilate(hookMap, ones(5, 5));

bg = imcomplement(gray) * (underlyingOpacity) + 255 * (1-underlyingOpacity);
if showHookMap
    for row=1:height
        for col=1:width
            if hookMap(row, col) == 1
                bg(row, col, :) = bg(row, col, :) * 0.75;
            end
        end
    end
end
%imshow(bg);
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
            text(x, staffRows(staffRow) - rowHeight, key, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
        end
    end
end

%hold off

% Construct output
strout = "";
for row=1:size(keys, 1)
    for col=1:size(keys, 2)
        if ~ismissing(keys(row, col))
            strout = strcat(strout, keys(row, col));
        end
    end
end

% Output to file
% fileID = fopen('output.txt','w');
% 
% for row=1:size(keys, 1)
%     for col=1:size(keys, 2)
%         if ~ismissing(keys(row, col))
%             fprintf(fileID, keys(row, col));
%             fprintf(fileID, ' ');
%         end
%     end
%     fprintf(fileID, '\n');
% end
% 
% fclose(fileID);
%%%%%%%%%%%%%%%%%%%%%%%%%%