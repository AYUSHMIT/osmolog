:- use_module(library(lists)).
:- use_module(library(clpfd)).
:- consult('core').
:-['infra','app'].
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% goAll returns the list of all full ranked placements
% Sample queries:
%   goForAll().
%
% goForAll(arApp, adaptive, full, 110, HeuP, HeuF, BestP, BestF, BestVC, BestC, WorstP, WorstF, WorstVC, WorstC, Time).
goForAll(AppName, AppVersion, PreferredMelVersion, MaxCost, HeuP, HeuF, BestP, BestF, BestVC, BestC, WorstP, WorstF, WorstVC, WorstC, Time) :-
        statistics(cputime, Start),
    findall((Placement, PlacementCost), placement(AppName, AppVersion, MaxCost, Placement, PlacementCost), Placements),
    evalPlacements(AppName, AppVersion, PreferredMelVersion, Placements, EvaluatedPlacements),
    sort(1,@>=,EvaluatedPlacements, SPlacements),
    SPlacements=[Best|_],
        statistics(cputime, Stop),
        Time is Stop - Start,
    nth0(0,Best,BestF),nth0(1,Best,BestVC), nth0(2,Best,BestC), nth0(3,Best,BestP),
    %writeln(Best),writeln(BestF),writeln(BestVC),writeln(BestC),writeln(BestP),
    last(SPlacements, Worst),
    nth0(0,Worst,WorstF),nth0(1,Worst,WorstVC), nth0(2,Worst,WorstC), nth0(3,Worst,WorstP),
    findHeuristicF(HeuP, HeuF, SPlacements).
    %writeln(Worst),writeln(WorstF),writeln(WorstVC),writeln(WorstC),writeln(WorstP).

findHeuristicF(HeuP, HeuF, SPlacements):-
    member([PF,_,_, P], SPlacements),
    sort(HeuP,HeuPSorted), sort(P,PSorted),
    PSorted = HeuPSorted,
    ( (ground(PF), HeuF is PF) ; HeuF = 200).

myPrint([]).
myPrint([X|Xs]):-write_ln(X),myPrint(Xs).

go(SortType, AppName, AppVersion, PreferredMelVersion, MaxCost, VC, C, Best, Time) :-
    statistics(cputime, Start),
    goForBest(SortType, AppName, AppVersion, PreferredMelVersion, MaxCost, BestPlacement),
    statistics(cputime, Stop), Time is Stop - Start,
    nth0(1,BestPlacement,VC), nth0(2,BestPlacement,C), nth0(3,BestPlacement,Best).

% goForBest returns the "best" full ranked placement according to the given SortType
%   SortType è una coppia (S,highest/lowest) usata per indicare:
%   - il valore del ranking rispetto a cui ordinare, ovvero formula (S=0), servizi (S=1), costo (S=2), e
%   - come ordinare (Highest o lowest)
% Sample queries:
%   goForBest((0,highest), smartHome, dunno, full, 40, Best).
%   goForBest(prolog, (2,lowest),  smartHome, dunno, full, 40, Best).
%   goForBest(clp,    (1,lowest),  smartHome, dunno, full, 40, Best).
goForBest(SortType, AppName, AppVersion, PreferredMelVersion, MaxCost, BestPlacement) :-
    findall((Placement, PlacementCost), placement(AppName, AppVersion, MaxCost, Placement, PlacementCost), Placements),
    evalPlacements(AppName, AppVersion, PreferredMelVersion, Placements, EvaluatedPlacements),
    best(SortType,EvaluatedPlacements,BestPlacement).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
placement(AppName, AppVersion, MaxCost, Placement, TotCost) :-
    application((AppName, AppVersion), MELs),
    melPlacementOK(MELs, Placement, [], 0, TotCost, MaxCost),
    findall(mel2mel(M1,M2,Latency), mel2mel_in_placement(M1,M2,Latency,Placement), FlowConstraints),
    flowsOK(FlowConstraints, Placement).

% evalPacements ranks a list of placements
evalPlacements(_, _, _, [], []).
evalPlacements(AppName, AppVersion, PreferredMelVersion, [(Placement,Cost)], [[_, VersionCompliance, Cost, Placement]]):-
    application((AppName, AppVersion), Mels), length(Mels, NMels), 
    findall(S, member(on(S, PreferredMelVersion, _), Placement), Ls), length(Ls, NPreferredVersionMels),
    VersionCompliance is div(100*NPreferredVersionMels,NMels).

evalPlacements(AppName, AppVersion, PreferredMelVersion, Placements, EvaluatedPlacements):-
    length(Placements, L), L>1, 
    application((AppName, AppVersion), Mels), length(Mels, NMels),
    maxANDmin(Placements, MinAllCosts, MaxAllCosts),
    findall([Formula, VersionCompliance, Cost, Placement], 
              (member((Placement, Cost), Placements), 
               findall(S, member(on(S, PreferredMelVersion, _), Placement), Ls), length(Ls, NPreferredVersionMels),
               VersionCompliance is div(100*NPreferredVersionMels,NMels),
               ( (MaxAllCosts-MinAllCosts > 0, NormalizedCost is div((100*(MaxAllCosts - Cost)),(MaxAllCosts - MinAllCosts))); NormalizedCost is 100 ),
               Formula is VersionCompliance + NormalizedCost),
             EvaluatedPlacements).

maxANDmin([(_, Cost)|Rest], MinCost, MaxCost) :- 
    length(Rest,L),L>0,
    maxANDmin(Rest, RestMinCost, RestMaxCost),
    ((Cost =< RestMinCost, MinCost is Cost); (Cost > RestMinCost, MinCost is RestMinCost)),
    ((Cost >= RestMaxCost, MaxCost is Cost); (Cost < RestMaxCost, MaxCost is RestMaxCost)).
maxANDmin([(_, Cost)], Cost, Cost). 

best(_, [], none).
best(_, [P], P).
best(ST, EPs, BestP) :- length(EPs, L), L>1, best2(ST, EPs, BestP).
best2(_, [E], E).
best2(ST, [E|Es], BestP) :- length(Es, L), L>0, best2(ST, Es, BestOfEs), choose(ST, E, BestOfEs, BestP).
choose((S,highest), E, BestOfEs, E) :- nth0(S, E, V), nth0(S, BestOfEs, W), V > W.
choose((S,highest), E, BestOfEs, BestOfEs) :- nth0(S, E, V), nth0(S, BestOfEs, W), V =<  W.
choose((S,lowest), E, BestOfEs, E) :- nth0(S, E, V), nth0(S, BestOfEs, W), V =< W.
choose((S,lowest), E, BestOfEs, BestOfEs) :- nth0(S, E, V), nth0(S, BestOfEs, W), V > W.
