%% === Load in curated seizures here === %%
pathToSeizures = '';  % PATH TO YOUR CURATED_SEIZURES .MAT FILE HERE
load(pathToSeizures,'curated_seizures');
oness = strcmp({seizures.type},'1');
twoss = strcmp({seizures.type},'2');
threess = strcmp({seizures.type},'3');
onesANDtwos = oness | twoss;
seizures = curated_seizures; % changing name to work with code below

%% Get the start and end times of all ground-truth (manually verified) seizures
GT_seizure_times = {seizures(onesANDtwos).time};
GT_stend = [];
for GTszi = 1:numel(GT_seizure_times)
    GT_stend(GTszi,:) = GT_seizure_times{GTszi}([1,end]);
end
fprintf('Found %d ground truth seizures\n',GTszi)

%%
% find how many detected seizures correspodn to actual seizures
FP = {}; % initialize the FALSE POSITIVE cell array (one element per test condition/threshold level)
TP = {};

for thi = 1:numel(threshList)

    eventTimes = CTX.time(seizIndies{thi}(1:end-1,[1,end])); % detected "events" %%%not sure why, but some parts of the last seizure are outside actual data boundaries, so I skip it for al seizures 
    TP{thi} = false(numel(GT_seizure_times),1); % TRUE POSITIVE vector

    % check for TRUE POSITIVES
    for GTszi = 1:size(GT_stend,1) %for each ground truth seizure
        A = GT_stend(GTszi,1); % START ground truth seizure
        B = GT_stend(GTszi,2); % END ground trth seizure
        startLog = A >= eventTimes(:,1) & A <= eventTimes(:,2); %
        endLog = B >= eventTimes(:,1) & B <= eventTimes(:,2);
        if any(startLog) || any(endLog)
            TP{thi}(GTszi) = true; % if there is overlap label that seizure as TRUE (i.e. 'correctly detected')
        end
    end
    TP_rate(thi) = sum(TP{thi})/numel(TP{thi}); % TRUE POSITIVE rate (TRUES detected/Actual TRUES)
    

    FP{thi} = true(size(eventTimes,1),1); 
    % check for FALSE POSITIVES
    for Dszi = 1:size(eventTimes,1)
        A = eventTimes(Dszi,1);
        B = eventTimes(Dszi,2);
        startLog = A >= GT_stend(:,1) & A <= GT_stend(:,2);
        endLog = B >= GT_stend(:,1) & B <= GT_stend(:,2);
        if any(startLog) || any(endLog)
            FP{thi}(Dszi) = false;
        end
    end
    FP_rate(thi) = sum(FP{thi})/numel(FP{thi}); % FALSE POSITIVE rate (TRUES detected/ALL Detected)
end

% Find optimal level
Performance = TP_rate - FP_rate;
[maxDiff, maxI] = max(TP_rate - FP_rate);
optThresh = threshList(maxI);

%% Plotting
figure;
subplot(121);
plot(FP_rate,TP_rate,'k','LineWidth',3);
hold on
plot([0 1],[0 1],'r--','LineWidth',3);
plot([-0.05 1.05],ones(1,2)*TP_rate(maxI),'k--');
plot(ones(1,2)*FP_rate(maxI),[-0.05 1.05],'k--');
scatter(FP_rate(maxI),TP_rate(maxI),108,'k', ...
    'LineWidth',2);
ylim([-0.05 1.05]);
xlim([-0.05 1.05]);
hold off
title('ROC Curve');
ylabel('True Positive Rate')
xlabel('False Positive Rate')
subplot(122);
plot(threshList,Performance,'k','LineWidth',3);
hold on
xl = xlim;
yl = ylim;
plot(ones(1,2)*optThresh,yl,'k--');
plot(xl,ones(1,2)*maxDiff,'k--');
scatter(threshList(maxI),Performance(maxI),108,'k', ...
    'LineWidth',2);
hold off
set(gca,'XDir','reverse');
title('Performance')
xlabel('Threshold (uV)')
ylabel('TP-FP Rate')
set(gcf().Children,'FontSize',24);

%% Plotting
figure;
np = 3; % number of plots
cpn = 1; %current plot number
% subplot below
sax(cpn) = subplot(1,np,cpn);
cpn = cpn+1;
plot(threshList, TP_rate,...
    'k','LineWidth',3);
set(gca,'XDir','reverse');
title('Sensitivity')
ylabel('Proportion of real seizures detected')
ylim([0 1]);
hold on
scatter(optThresh,TP_rate(maxI),108,'k', ...
    'LineWidth',2);
hold off
% xlabel('Threshold (uV)')

% subplot below
sax(cpn) = subplot(1,np,cpn);
cpn = cpn+1;
plot(threshList,1-FP_rate, ...
    'k','LineWidth',3);
set(gca,'XDir','reverse');
title('Accuracy');
ylabel('Proportion of detected events that are seizures')
ylim([0 1]);
xlabel('Threshold (uV)')
hold on
scatter(threshList(maxI),1-FP_rate(maxI),108,'k', ...
    'LineWidth',2);
hold off
% xticks([]);

% subplot below
sax(cpn) = subplot(1,np,cpn);
cpn = cpn+1;
eventCount = cellfun(@numel,FP);
plot(threshList, eventCount,...
    'k','LineWidth',3);
set(gca,'XDir','reverse');
title('Events')
ylabel('Count')
hold on
scatter(optThresh,eventCount(maxI),108,'k', ...
    'LineWidth',2);
hold off
set(gcf().Children,'FontSize',24);
  