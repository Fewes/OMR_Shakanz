clc;
path = 'img/im9s.jpg';
% Load and invert the image
RGB = imcomplement(imread(path));
% Convert to grayscale
gray = rgb2gray(RGB);
% Calculate optimal threshold
thres = graythresh(gray);
% Binarize the image
BW = imbinarize(gray, thres);
% Calculate the Hough transform of the image
[H, theta, rho] = hough(BW);

% Get the strongest line
% First column is rho index, second is theta index
P = houghpeaks(H, 1);
% Find out how much it needs to rotate
thetaPeak = theta(P(1, 2));

% Straighten the ORIGINAL image
RGB = imrotate(RGB, thetaPeak + 90, 'bicubic');
% Convert to grayscale
gray = rgb2gray(RGB);
% Calculate optimal threshold
thres = graythresh(gray);
% Binarize the image
BW = imbinarize(gray, thres);

s = ones(3:3);

BW = imdilate(BW,s);

staffLines = mean(BW');
plot(staffLines > 0.5);

%imshow(BW)

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