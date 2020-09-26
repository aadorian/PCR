------------------------- MODULE MainPCRFibPrimes3 -------------------------

(*
   Main module for PCR FibPrimes3.
*)

EXTENDS Typedef, FiniteSets

VARIABLES N, map1, map2 

----------------------------------------------------------------------------

NULL == CHOOSE x : /\ x \notin (VarPType1 \union VarCType1)
                   /\ x \notin (VarPType2 \union VarCType2)

\* Instanciate first PCR with appropiate types
PCR1 == INSTANCE PCRFibPrimes3 WITH 
  InType    <- InType1,
  CtxIdType <- CtxIdType1,
  IndexType <- IndexType1,
  VarPType  <- VarPType1,
  VarCType  <- VarCType1,
  VarRType  <- VarRType1,  
  map       <- map1,
  map2      <- map2

\* Instanciate second PCR with appropiate types  
PCR2 == INSTANCE PCRIsPrimeRec WITH
  InType    <- InType2,  
  CtxIdType <- CtxIdType2,
  IndexType <- IndexType2,
  VarPType  <- VarPType2,
  VarCType  <- VarCType2,
  VarRType  <- VarRType2,
  map       <- map2 
 
----------------------------------------------------------------------------

vars == <<N,map1,map2>>

Init == /\ N \in InType1
        /\ PCR1!Pre(N)
        /\ map1 = [I \in CtxIdType1 |-> 
                     IF   I = <<0>> 
                     THEN PCR1!InitCtx(N)
                     ELSE NULL]
        /\ map2 = [I \in CtxIdType2 |-> NULL]

(* PCR1 step at index I *)                  
Next1(I) == /\ map1[I] # NULL
            /\ PCR1!Next(I)
            /\ UNCHANGED N             

(* PCR2 step at index I *)   
Next2(I) == /\ map2[I] # NULL
            /\ PCR2!Next(I)
            /\ UNCHANGED <<N,map1>> 

Done == /\ \A I \in PCR1!CtxIndex : PCR1!Finished(I)
        /\ \A I \in PCR2!CtxIndex : PCR2!Finished(I)
        /\ UNCHANGED vars

Next == \/ \E I \in CtxIdType1 : Next1(I)
        \/ \E I \in CtxIdType2 : Next2(I)
        \/ Done
              
Spec == Init /\ [][Next]_vars

FairSpec == /\ Spec        
            /\ \A I \in CtxIdType1 : WF_vars(Next1(I))
            /\ \A I \in CtxIdType2 : WF_vars(Next2(I))                    

----------------------------------------------------------------------------

(* 
   Properties 
*)

isPrime(n) == LET div(k,m) == \E d \in 1..m : m = k * d
              IN n > 1 /\ ~ \E m \in 2..n-1 : div(m, n)
       
Fibonacci[n \in Nat] == 
  IF n < 2 
  THEN 1 
  ELSE Fibonacci[n-1] + Fibonacci[n-2]                

Solution(in) == LET fibValues == { Fibonacci[n] : n \in 0..in }
                IN  Cardinality({ f \in fibValues : isPrime(f) })

TypeInv == /\ N \in InType1
           /\ map1 \in PCR1!CtxMap
           /\ map2 \in PCR2!CtxMap

Correctness == []( PCR1!Finished(<<0>>) => PCR1!Out(<<0>>) = Solution(N) )
  
Termination == <> PCR1!Finished(<<0>>) 

GTermination == [][ PCR1!Finished(<<0>>) <=> Done ]_vars

\* This Spec is an implementation of PCRFibPrimes1!Spec.
\* The following def provides a refinement mapping to prove this fact.
subst ==                        
  [I \in DOMAIN map1 |-> 
     IF map1[I] # NULL                               \* For any well-defined PCR1 context with index I
     THEN [map1[I] EXCEPT                                 
       !.v_p= [i \in DOMAIN @ |-> 
                 IF @[i].r > 0                       \* For any read producer var v_p[i]s
                 THEN IF PCR2!Finished(I \o <<i>>)   \* If C_ret(I \o <i>) holds (PCR2 finished at I \o <i>)
                      THEN [v |-> @[i].v, r |-> 1]   \* then producer var is marked as read
                      ELSE [v |-> @[i].v, r |-> 0]   \* else we pretend is still unread.
                 ELSE @[i]
              ],
       !.v_c= [i \in DOMAIN @ |->                    \* For any consumer var v_c[i]
                 IF /\ PCR1!Read(map1[I].v_p, i)     \* for which corresponding v_p[i] has been read
                    /\ PCR2!Finished(I \o <<i>>)     \* and C_ret(I \o <i>) holds (PCR2 finished at I \o <i>)
                 THEN [v |-> PCR2!Out(I \o <<i>>),   \* then consumer var gets result computed by PCR2
                       r |-> @[i].r]                 
                 ELSE @[i]                           \* else leave it as is.
              ]              
          ]
     ELSE NULL]     
              
PCRFibPrimes1 == INSTANCE MainPCRFibPrimes1 WITH map1 <- subst

=============================================================================
\* Modification History
\* Last modified Sat Sep 26 01:19:18 UYT 2020 by josedu
\* Last modified Fri Jul 17 16:24:43 UYT 2020 by josed
\* Created Mon Jul 06 12:54:04 UYT 2020 by josed
