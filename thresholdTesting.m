%% Loading data
fpath = 'exampleInput.adicht'; % full filepath to .adicht file
saveName = 'thresholTestResults.mat'; % full filepath where you'd like to save the output
sample_blank_time = 8; % time (seconds) after threshold has been crossed when sampling is paused (like a "refactory period")
eegChannel = 1; % channel you want to use for event detection 
targetFS = 1000; % sampling frequency you'd like to use for the EEG data (1000Hz is default) 
minThresh = 0; % value to use for threshold-based detection (most sensitive threshold)
maxThresh = -1026; % max threshold (most conservative threhsold)
spaceBTWNthresh = 100; % gap between each threshold tested

%% Check for "seizures" (thresholding crossings) at multiple levels
CTX = adiLoadEEG(fpath,eegChannel,targetFS);
threshList = linspace(minThresh,maxThresh,spaceBTWNthresh);    % list of threshold values to try
blankOutWin = CTX.finalFS *sample_blank_time; % window in # of samples units
for ii = 1:numel(threshList)    % loop over the different thresholds
    loopClock = tic;
    fprintf('Running experiment at threshold level: %duV\n',...
        threshList(ii));                            % update the user with message in command window
    thresholdLog = CTX.data <= threshList(ii);       % logical vector of threshold crossings
    numSamps = numel(thresholdLog);                 %
    seizNum = 1;                                    % initialize the seizure number value starting seizure #1
    tInd = find(thresholdLog,seizNum,'first');      % time index of first threshold crossing
    thresholdLog([1+tInd(seizNum):tInd(seizNum)+blankOutWin]) = false; % apply the blank out after detected seizure
    tInd = find(thresholdLog,seizNum+1,'first');    % time indices of first 2 "seizures" (threshold crossings)
    stillCheck = true;                              % a flag to determine whether checking should stop or continue
    while stillCheck                                % WHILE, this flag is TRUE, keep looking for potential "seizures" (threshold crossings)
        if (tInd(end) -tInd(end-1)) > blankOutWin   % IF, the next seizure is NOT during the blank out window, proceed
            seizNum = seizNum + 1;                  % move to next seiz
        else                                        % ELSE, apply the blank-out window and try again
            thresholdLog([1+tInd(seizNum):tInd(seizNum)+blankOutWin]) = false; % apply the blank out after latest detected seizure
        end
        tInd = find(thresholdLog,seizNum+1,'first');        % time indices of first n "seizures" (threshold crossings)
        atEnd = (tInd(end) + blankOutWin) >= numSamps;      % check if end of recording is reached
        noMoreSeiz = numel(tInd) <= seizNum;                % check if no new "seizures" were detected
        if atEnd || noMoreSeiz                              % IF, the end of the recording is reached, OR no more seizures are detected, end the checking procedure
            stillCheck = false;
        end
    end
    addMat = repmat(0:blankOutWin-1,numel(tInd),1);             % matrix of blank out windows
    indMat = repmat(tInd,1,size(addMat,2));                  % matrix of "seizure" start times
    seizIndies{ii} = addMat + indMat;                       % matrix of indices to all "seizures"
    fprintf('Checking at %duV took %.2f seconds\n\n',...
    threshList(ii),toc(loopClock));             % print how long each loop iteration took
end

%% Save
save(saveName,'seizIndies',"threshList",'-v7.3');