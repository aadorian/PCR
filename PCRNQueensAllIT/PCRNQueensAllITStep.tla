----------------------- MODULE PCRNQueensAllITStep -------------------------

(*
   PCR NQueensAllITStep
   
   ---------------------------------------------------------------------
    fun divide, complete, abs, canAddQueenInRow, 
         canAddQueenInCell, canAddQueens, addQueenInRow, addQueen
     
     fun divide(B) = 
       cs = []
       for i in 1..Len(B)
         if canAddQueenInRow(B, i) then cs += [addQueenInRow(B, i)]
       return cs
        
     fun found(y, i) = if i > 0 then y[i] == y[i-1] else false
          
     pre NQueensAllIT = \forall r \in 1..Len(B) : B[r] == 0
   
     PCR NQueensAllIT(B : [Nat]) : {[Nat]}
       par
         p = produce id B
         forall p
           c = iterate found NQueensAllITStep [B]
         r = reduce id2 {} c
       
     PCR NQueensAllITStep(B : {[Nat]}) : {[Nat]}
       par
         c = produce elem B
         forall c
           cs = consume extend B c
         r = reduce \union {} B   
   ---------------------------------------------------------------------
*)

EXTENDS PCRNQueensAllITTypes, FiniteSets, PCRBase, TLC

----------------------------------------------------------------------------

(* 
   Basic functions                 
*)

abs(n) == IF n < 0 THEN -n ELSE n

\* check if queen can be placed in cell (r,c)
canAddQueenInCell(x, r, c) == 
  /\ x[r] = 0                                     \* not in same row
  /\ \A k \in DOMAIN x : x[k] # c                 \* not in same column
  /\ \A k \in DOMAIN x :                          \* not in same diagonal
        x[k] # 0 => abs(x[k] - c) # abs(k - r)

\* add queen in cell (r,c)                        
addQueen(x, r, c) == [x EXCEPT ![r] = c]                         

\* add queen in the first possible column of row r
addQueenInRow(x, r) == 
  LET N == Len(x)
      F[c \in Nat] ==
        IF c <= N
        THEN IF canAddQueenInCell(x, r, c)
             THEN addQueen(x, r, c)
             ELSE F[c+1]
        ELSE x 
  IN F[1]

\* check if queen can be placed in a row
canAddQueenInRow(x, r) == 
  LET N == Len(x)
      F[c \in Nat] ==
        IF c <= N
        THEN canAddQueenInCell(x, r, c) \/ F[c+1] 
        ELSE FALSE 
  IN F[1]      

\* check if is still possible to add queens in the unused rows
canAddQueens(x) == 
  LET N == Len(x)
      F[r \in Nat] ==
        IF r <= N
        THEN IF x[r] = 0
             THEN canAddQueenInRow(x, r) /\ F[r+1] 
             ELSE F[r+1]
        ELSE TRUE 
  IN F[1] 

\* produce further configurations each with a legally placed new queen
divide(x) == 
  LET N == Len(x)
      F[r \in Nat] ==
        IF r <= N
        THEN IF canAddQueenInRow(x, r)
             THEN <<addQueenInRow(x, r)>> \o F[r+1]
             ELSE F[r+1]
        ELSE <<>> 
  IN F[1]    

elem(x, p, I, i) == SetToSeq(x)[i]

complete(c) == \A r \in DOMAIN c : c[r] # 0

extend(x, p, I, i) == IF complete(p[i].v) THEN { p[i].v } ELSE ToSet(divide(p[i].v))

concat(x, o, c, I, i) == o \union c[i].v

----------------------------------------------------------------------------

(* 
   Iteration space                 
*)

lowerBnd(x) == 1
upperBnd(x) == Cardinality(x)
step(i)     == i + 1  
eCnd(r)     == FALSE
 
INSTANCE PCRIterationSpace WITH
  lowerBnd  <- lowerBnd,
  upperBnd  <- upperBnd,  
  step      <- step

----------------------------------------------------------------------------

(* 
   Initial conditions        
*)

r0(x) == [v |-> {}, r |-> 0]

initCtx(x) == [in  |-> x,
               v_p |-> [i \in IndexType |-> Undef],
               v_c |-> [i \in IndexType |-> Undef],
               v_r |-> [i \in IndexType |-> r0(x)],             
               i_r |-> lowerBnd(x),
               ste |-> "OFF"] 

pre(x) == TRUE

----------------------------------------------------------------------------
            
(* 
   Producer action
   
   FXML:  forall i \in 1..Len(B)
            c[i] = elem B[i]             
   
   PCR:   c = produce elem B                            
*)
P(I) == 
  \E i \in iterator(I) : 
    /\ ~ written(v_p(I), i)         
    /\ cm' = [cm EXCEPT  
         ![I].v_p[i] = [v |-> elem(in(I), v_p(I), I, i), r |-> 0] ]             
\*    /\ PrintT("P" \o ToString(I \o <<i>>) \o " : " \o ToString(v_p(I)[i].v'))                  

(* 
   Consumer action
   
   FXML:  forall i \in Dom(p)
            cs[i] = extend B c[i]

   PCR:   cs = consume extend B c
*)
C(I) == 
  \E i \in iterator(I) :
    /\ written(v_p(I), i)
    /\ ~ written(v_c(I), i)
    /\ cm' = [cm EXCEPT 
         ![I].v_p[i].r = @ + 1, 
         ![I].v_c[i]   = [v |-> extend(in(I), v_p(I), I, i), r |-> 0]]                                          
\*    /\ PrintT("C" \o ToString(I \o <<i>>) \o " : P" \o ToString(i) 
\*                  \o " con v=" \o ToString(v_p(I)[i].v))  
  
(* 
   Reducer action
   
   FXML:  ...

   PCR:   c = reduce [] conquer c
*)
R(I) == 
  \E i \in iterator(I) :
    /\ written(v_c(I), i)
    /\ pending(I, i)
    /\ LET newOut == concat(in(I), out(I), v_c(I), I, i)
           endSte == rDone(I, i) \/ eCnd(newOut)
       IN  cm' = [cm EXCEPT 
             ![I].v_c[i].r = @ + 1,
             ![I].v_r[i]   = [v |-> newOut, r |-> 1],
             ![I].i_r      = i,
             ![I].ste      = IF endSte THEN "END" ELSE @]                                                                            
\*          /\ IF endSte
\*             THEN PrintT("R" \o ToString(I \o <<i>>) 
\*                             \o " : in= "  \o ToString(in(I))    
\*                             \o " : ret= " \o ToString(out(I)')) 
\*             ELSE TRUE

(* 
   PCR NQueensAllITStep step at index I 
*)
Next(I) == 
  \/ /\ state(I) = "OFF" 
     /\ Start(I)
  \/ /\ state(I) = "RUN" 
     /\ \/ P(I)
        \/ C(I) 
        \/ R(I)
        \/ Quit(I)  
 
=============================================================================
\* Modification History
\* Last modified Tue Dec 15 21:00:44 UYT 2020 by josedu
\* Last modified Fri Jul 17 16:28:02 UYT 2020 by josed
\* Created Mon Jul 06 13:03:07 UYT 2020 by josed
