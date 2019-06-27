%% SECTION 1
%This script takes the logical sleep vector from the spectral analysis
%results and finds the start and end of each sleep cycle in the 10kHz EMG.
%It rejects cases %in which the start or end of a run is in the middle of
%a sleep cycle.  It then makes a vector listing all of the sleep cycle
%durations.

% It then scans through the logical array and removes any sleep cycles
% whose durations are less than a criterion set by the user.  It also
% combined sleep cycles that are separated by wake inervals less than a
% criteron set by the user.  The default criteria are currently 40 samples
% (2 sec at 20Hz frame rate)  for the shortest interval that can separaate
% two sleep cycles without having them combined and 200 samples (10 sec at
% 20 Hz frame rate) for the shortest sleep cycle that is accepted.

% Note that the logical arrays used have % already been set to match frames
%rather than EMG points by the spectral analysis routine.

%Finally, the modified logical sleep frame vector is upsamples to match the
%1kHz EMG.  Two new EMG vectors are then created, one for sleep and one for
%wake.  The transition state from the spectral analysis is ignored.   These
%vectors have the 1 kHz EMG points during sleep and wake, respectively, and
%NaN for the other points.  Plotting both on the same fraph gives you a
%color-coded single 1kHz EMG, with sleep in blue and wake in red.

%At the end is a template that calculates the fraction of time spent in
%both sleep and wake when the Ca signal or Area Fraction signal is above
%criterion, using both original logical sleep vectors from the spectral
%analysis routine, and the modified logical sleep vectors from the criteria
%in this script.




SleepComponent=1;     %Enter the component from the spectral analysis that represents sleep

%Data = SpectDataResults.Component(SleepComponent).FrameLogical;
Data = SpectDataResults.Component(SleepComponent).FrameLogical;
Starts = find(diff(Data)==1);        %Find start of each sleep cycle
Ends = find(diff(Data)==-1);         %Find end of each sleep cycle

clear 'Data';





%If run starts in the middle of a sleep cycle, set flag to remove that end
%point from the vector.  You can't actually remove it until after you have
%also set the flag for the case where the run ends in the middle of a sleep
%sycle.

if Starts(1)>Ends(1)
    EndsFlag=1;
else
    EndsFlag=0;
end


%Same as above for case where run ends during a sleep cycle.
if Starts(size(Starts))>Ends(size(Ends))
    StartsFlag=1;
else
    StartsFlag=0;
end






%If run starts during a sleep cycle, remove the end of that cycle from the
%vector.
if EndsFlag==1
     Ends=Ends(2:size(Ends,2));
end


%If run ends during a sleep cycle, remove the start of that cycle from the
%vector.  
if StartsFlag==1
   Starts=Starts(1:size(Starts,2)-1);
end



%ModifiedEnds=Ends;
%ModifiedStarts=Starts;
%Get durations of all full sleep cycles.
SleepDurations=Ends-Starts;


%If two sleep cycles are separated by a wake cycle less than 2 sec,
%eliminate that wake cycle and combine the two sleep cycles.

MinimumGap = FrameRate*5;
%MinimumGap=0;
ModSleepFrameLogical=SpectDataResults.Component(1).FrameLogical;
for n = 2:size(Starts,2)
       if  Starts(n)-Ends(n-1)<MinimumGap
              ModSleepFrameLogical(Ends(n-1):Starts(n))=1;
       end
   end



%Using the logical sleep cycle array modofied above to combine sleep cycles
%separated by wake cycles < 2sec, remove all wake cycles that last <2 sec
%and combine the flanking wake cycles.


MinimumDuration = FrameRate*10;
ModifiedStarts = find(diff(ModSleepFrameLogical)==1);
ModifiedEnds   = find(diff(ModSleepFrameLogical)==-1);

ModifiedSleepFrameLogical=ModSleepFrameLogical;
   for n = 1:size(ModifiedStarts,2)
       if ModifiedEnds(n)-ModifiedStarts(n)<MinimumDuration
           ModifiedSleepFrameLogical(ModifiedStarts(n):ModifiedEnds(n))=0;
       end
   end
   


%Gets durations of all sleep events after removing sleep events in progress
%at start or end of trace (already done above) AND eliminating sleep cycles
%less then 2 sec in duration AND combining sleep cycles separated by wake
%events less then 2 sec in duration
ModifiedStarts = find(diff(ModifiedSleepFrameLogical)==1);
ModifiedEnds   = find(diff(ModifiedSleepFrameLogical)==-1);
ModifiedDurations=ModifiedEnds-ModifiedStarts;

%Gets durations of all wake events subject to the above corrections.
for n = 2:size(ModifiedStarts,2)
    ModifiedIntervals(n-1)=ModifiedStarts(n)-ModifiedEnds(n-1);
end



%Upsamples the ModifiedSleepFrameLogical to match the 1kHz EMG vector size.
%Can't resample a logical array, so convert to double first.
%Resampling creates some ringing at the start and end of each sleep cycle
%in the array, so variable C is created to eliminate this.  Two vectors are
%created, on each for sleep and wake cycle EMGs.  Each is filled with NaN
%for the rest of the time so they can be plotted together in different
%colors.  The script ends by plotting the 1 kHz EMG in black and a
%color-coded 1 kHz EMG with sleep in blue (yawn) and wake in red (GET UP!).

A=double(ModifiedSleepFrameLogical);
B=resample(A,1000/FrameRate,1);
C=B>0.5;
C=C(1:size(OnekHzEMG,2));
SleepEMG=nan(size(OnekHzEMG));
SleepEMG(C==1)=OnekHzEMG(C==1);
WakeEMG=nan(size(OnekHzEMG));
WakeEMG(C==0)=OnekHzEMG(C==0);

step=FrameRate/1000;
x=[1:step:size(GlobalCaSignal,1)+10-(FrameRate/1000)];
    
%% 

%Plots the OnekHzEMG as a single plot with sleep in blue and wake in red
figure;
s=plot(x,(SleepEMG/5)+1,'b');
hold on
w=plot(x,(WakeEMG/5)+1,'k');
%s=plot(ModifiedSleepFrameLogical-2,'k');

xlim([1,size(GlobalCaSignal,1)]);
%Ca=plot((GlobalCaSignal)-0.1,'k','LineWidth',1.5);
fr=plot(AreaFractionOverHalfMax,'k','LineWidth',1.5);
%Mot=plot(Motor,'k','LineWidth',1.5);
%Pir=plot(Piriform,'c','LineWidth',1);
%up=plot(UP,'k','LineWidth',1);
%down=plot(DOWN,'k','LineWidth',3);


%% 

%Marks all Sleep cycles with a semi-transparent blue rectangle.  This is
%intended for plots with EMG in black, sleep cycle marker from Section 2A,
%and some combination of Fractional Area and Mean Ca Signal in black.

%figure
%hold on
for n = 1:size(ModifiedDurations,2)
    rectangle('Position',[ModifiedStarts(n),-0.5,ModifiedDurations(n),2],'FaceColor',[0 0 1 0.2],'EdgeColor',[0 0 1 0.2]);
end


%% 
%Gets GlobalCaSignal separately for Sleep and Wake.  This allows
%calculation of mean and sem for each and p value.


GlobalSleep=GlobalCaSignal(ModifiedSleepFrameLogical==1);
GlobalWake=GlobalCaSignal(ModifiedSleepFrameLogical==0);

%% 
%Same as above for Area Fraction variable

SleepFraction=AreaFractionOverHalfMax(ModifiedSleepFrameLogical==1);
WakeFraction=AreaFractionOverHalfMax(ModifiedSleepFrameLogical==0);

%% 
%Calculates fraction of total sleep or wake time spent with area active >50%

AFSleep=AreaFractionOverHalfMax(ModifiedSleepFrameLogical==1);
AFWake=AreaFractionOverHalfMax(ModifiedSleepFrameLogical==0);
logicalAFSleep=AFSleep>0.5;
logicalAFWake=AFWake>0.5;
TimeFractionSleep = sum(logicalAFSleep) / size(AFSleep,1);
TimeFractionWake = sum(logicalAFWake) / size(AFWake,1);
clear 'AFSleep'
clear 'AFWake'
clear 'logicalAFSleep'
clear 'logicalAFWake'


%% 
%Returns the maximum fraction of cortical area active for each sleep cycle.
for n = 1:size(ModifiedDurations,2)
    MaxArea(n) = max(AreaFractionOverHalfMax(ModifiedStarts(n):ModifiedEnds(n)));
end

%%  SECTION 9
%Calculate lag times from sleep onset to wave onset for all sleep cycles
%that have waves.  Script first initializes the lagtimes variable to the
%number of sleep cycles in the run, and fills it with NaN.  Initializes the
%abslag times variable and fills it with zeros.  The for... loop runs
%through all sleep cycles and asks if  if 2 criteria are met: there is a
%wave present (using the WaveExistInSleep variable from the above script),
%and that the activity at the start of the cycle covers less than 2% of the
%cortex (to avoid cycles where activity is already in progress).  It then
%the frame when the event rises to 10% of its maximum cortical area coverage.
%This 'lagtimes' variable is referenced by the 'find' function to the start
%of the event.  The script then calculates the absolute frame (referenced
%to the start of the entire run) for the start of that wave.  Both
%variables are transposed.  The script then creates a 
%'logicalabslagtimes variable  so that a marker of all wave starts can be 
%plotted to check that the script worked properly.  The script ends by 
%creating a variable durations of 
%sleep cycles in the run that do not contain a wave.  The allows asking the
%question of whether waves occur earlier in long sleep cycles than
%predicted by the duration of cycles that do not contain waves.

LagTimes(1:size(ModifiedDurations,2))=NaN;
AbsLagTimes(1:size(ModifiedDurations,2))=0;
for n = 1:size(ModifiedDurations,2)
    if (WaveExistInSleep(n)==1) && (AreaFractionOverHalfMax(ModifiedStarts(n))<0.02)
        LagTimes(n)=find(AreaFractionOverHalfMax(ModifiedStarts(n):ModifiedEnds(n)) > 0.1 * max(AreaFractionOverHalfMax(ModifiedStarts(n):ModifiedEnds(n))),1);
        AbsLagTimes(n)=LagTimes(n) + ModifiedStarts(n);
    end
end
AbsLagTimes=AbsLagTimes';
LagTimes=LagTimes';

%%
LogicalAbsLagTimes=GlobalCaSignal;
LogicalAbsLagTimes(1:40000)=0;
LogicalAbsLagTimes(AbsLagTimes(AbsLagTimes~=0))=1;

YesWaveSleepCycleDurations=ModifiedDurations(WaveExistInSleep==1);
NoWaveSleepCycleDurations=ModifiedDurations(WaveExistInSleep==0);
LagTimesList=LagTimes(isfinite(LagTimes))';

% Get median lag time and probability of waves in sleep < and < mlt
MeanLagTime=mean(LagTimesList)/FrameRate;
MedianLagTime=median(LagTimesList)/FrameRate;

idxm=find(ModifiedDurations<=FrameRate*MedianLagTime);
ProbWaveSleepUnderMedianLagTime=sum(WaveExistInSleep(idxm))/size(WaveExistInSleep(idxm),1);

idxm1=find(ModifiedDurations>FrameRate*MedianLagTime);
ProbWaveSleepOverMedianLagTime=sum(WaveExistInSleep(idxm1))/size(WaveExistInSleep(idxm1),1);















        














































