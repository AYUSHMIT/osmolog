% effettua il placement dei servizi specificati nell'applicazione con massimo costo
% tagliando quando il costo del placement supera quello massimo
melPlacementOK([], [], _, PlacementCost, PlacementCost, _).
melPlacementOK([(M, Version)| Ss], [on(M, Version, N)|P], AllocatedHW, CostUpToNow, TotalCost, MaxCost) :-
    placementOK((M, Version), N, AllocatedHW, NewAllocatedHW, NodeCost),
    % aggiorno costo del placement e interrompo la costruzione se si è superato il massimo costo accettabile
    NewCost is CostUpToNow + NodeCost,
    NewCost =< MaxCost,
    melPlacementOK(Ss, P, NewAllocatedHW, NewCost, TotalCost, MaxCost).

% effettua il placement di un servizio su un nodo che può ospitarlo
placementOK((M, Version), N, AllocatedHW, NewAllocatedHW, NodeCost) :- 
	mel((M, Version), SW_Reqs, HW_Reqs, Thing_Reqs),
	node(N, SW_Caps, HW_Caps, Thing_Caps),
    swReqsOK(SW_Reqs, SW_Caps, NodeSwCost),
    thingReqsOK(Thing_Reqs, Thing_Caps, NodeThingCost),
    hwReqsOK(HW_Reqs, HW_Caps, N, AllocatedHW, NewAllocatedHW, NodeHwCost),
    NodeCost is NodeSwCost + NodeThingCost + NodeHwCost. 
    
% controlla se i requisiti sw richiesti dal servizio sono disponibili e in tal caso restituisce il costo
swReqsOK(SW_Reqs, SW_Caps, Cost) :- costIfCapsOK(SW_Reqs, SW_Caps, Cost).

% controlla se i requisiti iot richiesti dal servizio sono disponibili e in tal caso restituisce il costo
thingReqsOK(T_Reqs, T_Caps, Cost) :- costIfCapsOK(T_Reqs, T_Caps, Cost).

% controlla se le capabilities richieste dal servizio sono disponibili e in caso positivo restituisce il costo
costIfCapsOK([], _, 0).
costIfCapsOK([Cap| CWs], Caps, TotalCost) :-
   member((Cap, Cost), Caps), % controllo se la capability è presente e in tal caso prendo il costo
   costIfCapsOK(CWs, Caps, Rest),
   TotalCost is Cost + Rest.

% controlla se i requisiti hw richiesti dal servizio sono disponibili e in tal caso restituisce il costo
%called with    hwReqsOK(HW_Reqs, HW_Caps, N, AllocatedHW, NewAllocatedHW, NodeHwCost),
hwReqsOK(HW_Reqs, (HW_Cap, Cost), N, AllocatedHW, NewAllocatedHW, NodeHwCost) :-
    HW_Reqs =< HW_Cap,
    hwReqsOK2(HW_Reqs, (HW_Cap, Cost), N, AllocatedHW, NewAllocatedHW, NodeHwCost).

hwReqsOK2(HW_Reqs, (HW_Cap, Cost), N, [], [(N,HW_Reqs)], HwCost) :- 
    HW_Reqs =< HW_Cap, HwCost is HW_Reqs * Cost.
hwReqsOK2(HW_Reqs, (HW_Cap, Cost), N, [(N,A)|As], [(N,NewA)|As], HwCost) :-
    HW_Reqs + A =< HW_Cap, NewA is A + HW_Reqs, HwCost is HW_Reqs * Cost.
hwReqsOK2(HW_Reqs, HW_Caps, N, [(N1,A1)|As], [(N1,A1)|NewAs], HwCost) :-
    dif(N,N1), hwReqsOK2(HW_Reqs, HW_Caps, N, As, NewAs, HwCost).

% prendo tutti gli s2s dei servizi presenti nel placement
mel2mel_in_placement(S1, S2, Latency, P) :-
    mel2mel(S1, S2, Latency),
    subset([on(S1, _, _), on(S2, _, _)], P).

% controlla se la latenza fra i nodi dove sono stati piazzati i servizi rispetta le latenze massime specificate dall'applicazione
flowsOK([], _).
flowsOK([mel2mel(S1,S2,_)|SFs], P) :-
    member(on(S1, _, N), P), member(on(S2, _, N), P),
    flowsOK(SFs, P).
flowsOK([mel2mel(S1,S2,L)|SFs], P) :-
    member(on(S1, _, N1), P), member(on(S2, _, N2), P), dif(N1,N2),
    e2elink(N1,N2,Latency), 
    Latency =< L,
    flowsOK(SFs, P).

%e2eLink ha successo se esiste un link fra i nodi N1 e N2 o fra N2 e N1.
e2eLink(N1,N2,L) :-
    link(N1,N2,L).
e2elink(N1,N2,L) :-
    link(N2,N1,L).