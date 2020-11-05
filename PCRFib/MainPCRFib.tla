--------------------------- MODULE MainPCRFib ------------------------------

(*
   Main module for PCR Fib.
*)

EXTENDS Typedef, FiniteSets

VARIABLES N, cm1, im1

----------------------------------------------------------------------------
         
\* Instanciate root PCR with appropiate types
PCR1 == INSTANCE PCRFib WITH
  InType    <- InType1,
  CtxIdType <- CtxIdType1,
  IndexType <- IndexType1,   
  VarPType  <- VarPType1,
  VarCType  <- VarCType1,
  VarRType  <- VarRType1, 
  cm        <- cm1,
  im        <- im1

Undef == PCR1!Undef

----------------------------------------------------------------------------

vars == <<N,cm1,im1>>

Init == /\ N \in InType1
        /\ PCR1!pre(N) 
        /\ cm1 = [I \in CtxIdType1 |-> 
                      IF   I = <<>> 
                      THEN PCR1!initCtx(N)
                      ELSE Undef]  
        /\ im1 = [I \in CtxIdType1 |-> 
                     IF   I = <<>> 
                     THEN PCR1!lowerBnd(N)
                     ELSE Undef]                               
                          
Next1(I) == /\ cm1[I] # Undef
            /\ PCR1!Next(I)
            /\ UNCHANGED N              

Done == /\ \A I \in PCR1!CtxIndex : PCR1!finished(I)
        /\ UNCHANGED vars

Next == \/ \E I \in CtxIdType1 : Next1(I)
        \/ Done
              
Spec == Init /\ [][Next]_vars

FairSpec == /\ Spec            
            /\ \A I \in CtxIdType1 : WF_vars(Next1(I))

----------------------------------------------------------------------------

(* 
   Properties 
*)

fibonacci[n \in Nat] == 
  IF n < 2 
  THEN 1 
  ELSE fibonacci[n-1] + fibonacci[n-2]                

Solution(in) == fibonacci[in]

TypeInv == /\ N \in InType1
           /\ cm1 \in PCR1!CtxMap
           /\ im1 \in PCR1!IndexMap

Correctness == []( PCR1!finished(<<>>) => PCR1!out(<<>>) = Solution(N) )
  
Termination == <> PCR1!finished(<<>>) 
  
=============================================================================
\* Modification History
\* Last modified Wed Oct 28 19:55:58 UYT 2020 by josedu
\* Created Sat Aug 08 21:17:14 UYT 2020 by josedu
