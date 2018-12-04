function [staffRow, key] = NoteProfile(y, staffRows, rowHeight)
    %NOTEPROFILE Get note profile (parent row and key)
    
    % Key indexing array
    keys = [
        "G1"
        "A1"
        "B1"
        "C2"
        "D2"
        "E2"
        "F2"
        "G2"
        "A2"
        "B2"
        "C3"
        "D3"
        "E3"
        "F3"
        "G3"
        "A3"
        "B3"
        "C4"
        "D4"
        "E4"
        
        "g1"
        "a1"
        "b1"
        "c2"
        "d2"
        "e2"
        "f2"
        "g2"
        "a2"
        "b2"
        "c3"
        "d3"
        "e3"
        "f3"
        "g3"
        "a3"
        "b3"
        "c4"
        "d4"
        "e4"
       ];
    
    % ----- Determine which staff row this note belongs to -----
    % Track the previous index
    prevIndex = 0;
    for i=1:length(staffRows)
        if y < staffRows(i)
            % Note belongs to either the current or previous row
            % Case 1: There is no previous row
            if prevIndex == 0
                staffRow = i;
            % Case 2: There is no next row
            elseif i > length(staffRows)
                staffRow = length(staffRows);
            % Case 3: Note is between current and previous row
            else
                distUpper = y - staffRows(prevIndex);
                distLower = staffRows(i) - y;
                if distUpper < distLower
                    staffRow = prevIndex;
                else
                    staffRow = i;
                end
            end
            break
        elseif i == length(staffRows)
            % Reached the end, assume the note belongs to the bottom row
            staffRow = length(staffRows)
        end
        prevIndex = i;
    end
    
    % ----- Determine the note key -----
    % The spacing between two staff lines
    staffSpacing = rowHeight / 4;
    % The spacing between two keys
    keyDelta = staffSpacing / 2;
    % Distance from note to the row it belongs to
    keyDist = y - staffRows(staffRow);
    % Calculate a key index
    keyIndex = -round(keyDist / keyDelta);
    % Move into the correct range (1-40)
    keyIndex = keyIndex + 9 + 1;
    % Use the key array to set the key string
    key = keys(keyIndex);
    
    key
end

