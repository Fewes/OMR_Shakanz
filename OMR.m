clc;

% Define some parameters
path = 'img/im1s.jpg';     % Path to image being processed
angleSpan = 5;              % Minimum/maximum image rotation to correct
angleDelta = 0.05;          % Image rotation correction step size


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
imshow(RGB);

% Convert to grayscale
gray = rgb2gray(RGB);
% Calculate optimal threshold
thres = graythresh(gray);
% Binarize the image
BW = imbinarize(gray, thres);

% Get the staff line profile
[staffLines, staffRows, rowHeight] = StaffProfile(BW);

% Stretch the result and show it
imshow(repmat(staffLines, 1, width));

% Show staff row ranges
imshow(BW);
hold on
for row = staffRows
    % Row center
    plot([1, width], [row row], 'green');
    % Row edges
    plot([1, width], [row+rowHeight/2 row+rowHeight/2], 'yellow');
    plot([1, width], [row-rowHeight/2 row-rowHeight/2], 'yellow');
end

% Get profile of a debug note
note_x = 100;
note_y = 185;

% Notes are stored in a row matrix, like this:
% [x, y] % Note 1
% [x, y] % Note 2
% [x, y] % Note 3
% [x, y] % Note 4
% ...
% They are sorted based on their x-coordinates

notes = rand(32, 2);
notes(:, 2) = notes(:, 2) * height;
notes(:, 1) = notes(:, 1) * width;

% 3D Matrix containing the notes on each staff row
keys = zeros(2, 1, length(staffRows));

keys(:, 4, 2) = ones(2, 1);

indices = ones(1, length(staffRows));

for row=1:size(notes,1)
    % Note coordinates
    x = notes(row, 1);
    y = notes(row, 2);
    
    % Get the note profile
    [staffRow, key] = NoteProfile(y, staffRows, rowHeight);
    
    keys(:, indices(1, staffRow), staffRow) = [x y];
    indices(1, staffRow) = indices(1, staffRow)+1;

    % Plot line
    plot([x, x], [staffRows(staffRow) y], 'red');
    % Plot note
    plot(x, y, 'r*');
end

% for row=1:size(notes,1)
%     % Get the note profile
%     [staffRow, key] = NoteProfile(notes(row, 2), staffRows, rowHeight);
% 
%     % Plot line
%     plot([note_x, note_x], [staffRows(staffRow) note_y], 'red');
%     % Plot note
%     plot(note_x, note_y,'r*');
% end

hold off

%%

imshow(H,[],'XData',T,'YData',R,...
            'InitialMagnification','fit');
xlabel('\theta'), ylabel('\rho');
axis on, axis normal, hold on;

P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
x = T(P(:,2)); y = R(P(:,1));
plot(x,y,'s','color','white');

lines = houghlines(BW,T,R,P,'FillGap',5,'MinLength',7);
figure, imshow(RGB), hold on
max_len = 0;
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

   % Plot beginnings and ends of lines
   plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
   plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');

   % Determine the endpoints of the longest line segment
   len = norm(lines(k).point1 - lines(k).point2);
   if ( len > max_len)
      max_len = len;
      xy_long = xy;
   end
end