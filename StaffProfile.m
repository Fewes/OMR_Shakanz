function [staffLines, staffRows, rowHeight] = StaffProfile(BW)
    %STAFFPROFILE Set up the staff lines profile to be used for note
    %classification

    % Dilation filter
    s1 = ones(3:3);
    % Dilate the image
    BW = imdilate(BW, s1);

    % Calculate the mean value of each row
    staffLines = mean(BW');
    % Threshold the result to find stafflines only
    % After this operation, stafflines are stored in a vertical vector
    staffLines = imbinarize(staffLines', 0.5);

    % Dilate staff lines to get a solid block for each row
    s2 = ones(10:10);
    staffBlocks = imclose(staffLines, s2);
    % Also undo the dilation at the top to get a more accurate result
    staffBlocks = imerode(staffBlocks, s1);

    % Loop through staff line blocks
    b           = false;
    startPos    = 0;
    rowPos      = 1;
    rowHeight   = 0;
    % Find staff line rows
    for i=1:length(staffBlocks)
      %elm = staffLines(i);
        if staffBlocks(i) && ~b
            % Store start position of row block
            startPos = i;
            % Set row flag
            b = true;
        elseif ~staffBlocks(i) && b
            % Increment average row heiht value
            rowHeight = rowHeight + (i - startPos);
            % Get row middle position
            staffRows(rowPos) = (startPos + i) / 2;
            % Increment row index counter
            rowPos = rowPos+1;
            % Reset row flag
            b = false;
        end
    end

    % Need to average this before returning
    rowHeight = rowHeight / length(staffRows);

end
