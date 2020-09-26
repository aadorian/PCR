------------------------ MODULE MainPCRFibRec --------------------------

(*
   Main module for PCR FibRec.
*)

EXTENDS Typedef, FiniteSets

VARIABLES N, map1

----------------------------------------------------------------------------

NULL == CHOOSE x : x \notin (VarPType1 \union VarCType1)
         
\* Instanciate root PCR with appropiate types
PCR1 == INSTANCE PCRFibRec WITH
  InType    <- InType1,
  CtxIdType <- CtxIdType1,
  IndexType <- IndexType1,   
  VarPType  <- VarPType1,
  VarCType  <- VarCType1,
  VarRType  <- VarRType1, 
  map       <- map1

----------------------------------------------------------------------------

vars == <<N,map1>>

Init == /\ N \in InType1
        /\ PCR1!Pre(N) 
        /\ map1 = [I \in CtxIdType1 |-> 
                      IF   I = <<0>> 
                      THEN PCR1!InitCtx(N)
                      ELSE NULL]       
                                 
(* PCR1 step at index I *)                           
Next1(I) == /\ map1[I] # NULL
            /\ PCR1!Next(I)
            /\ UNCHANGED N              

LOCAL INSTANCE TLC

Done == /\ \A I \in PCR1!CtxIndex : PCR1!Finished(I)
        /\ UNCHANGED vars
\*        /\ PrintT("ret " \o ToString(PCR1!in(<<0>>)) \o " : " \o ToString(PCR1!Out(<<0>>)))

Next == \/ \E I \in CtxIdType1 : Next1(I)
        \/ Done
              
Spec == Init /\ [][Next]_vars

FairSpec == /\ Spec            
            /\ \A I \in CtxIdType1 : WF_vars(Next1(I))

----------------------------------------------------------------------------

(* 
   Properties 
*)

Fibonacci[n \in Nat] == 
  IF n < 2 
  THEN 1 
  ELSE Fibonacci[n-1] + Fibonacci[n-2]                

Solution(in) == Fibonacci[in]

TypeInv == /\ N \in InType1
           /\ map1 \in PCR1!CtxMap

Correctness == []( PCR1!Finished(<<0>>) => PCR1!Out(<<0>>) = Solution(N) )
  
Termination == <> PCR1!Finished(<<0>>) 
  
=============================================================================
\* Modification History
\* Last modified Sat Sep 26 15:40:58 UYT 2020 by josedu
\* Created Sat Aug 08 21:17:14 UYT 2020 by josedu
