-------------------------- MODULE PCRIsPrimeSeq ----------------------------

(*
   PCR IsPrimeSeq
   
   ----------------------------------------------------------
     fun divisors, notDivides, and
     
     lbnd divisors = lambda x. 2 
     ubnd divisors = lambda x. Sqrt(x)
     step divisors = lambda x. if x == 2 then 3 else x+2
     
     fun divisors(N,p,i) = i
     fun notDivides(N,p,i) = not (N % p[i] == 0)
     fun and(r1,r2) = r1 && r2 
        
     PCR IsPrimeSeq(N):
       par
         p = produceSeq divisors N
         forall p
           c = consume notDivides N p
         r = reduce and (N > 1) c
   ----------------------------------------------------------
*)

EXTENDS PCRIsPrimeSeqTypes, PCRBase, TLC

VARIABLE im

----------------------------------------------------------------------------

(* 
   Basic functions                     
*)

divisors(x, p, I, i) == i
   
notDivides(x, p, I, i) == ~ (x % p[i].v = 0)

and(x, o, c, I, i) == o /\ c[i].v 

----------------------------------------------------------------------------

(* 
   Iteration space                 
*)    
          
lowerBnd(x) == 2
upperBnd(x) == Sqrt(x)
step(i)     == IF i = 2 THEN 3 ELSE i + 2          
eCnd(r)     == FALSE
 
INSTANCE PCRIterationSpaceSeq WITH
  lowerBnd  <- lowerBnd,
  upperBnd  <- upperBnd,  
  step      <- step

----------------------------------------------------------------------------

(* 
   Initial conditions        
*)

r0(x) == [v |-> x > 1, r |-> 0]

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
   
   FXML:  for (i=LowerBnd(N); i < UpperBnd(N); Step(i))
            p[i] = divisors N            
   
   PCR:   p = produceSeq divisors N                              
*)
P(I) == 
  /\ i_p(I) \in iterator(I) 
  /\ cm' = [cm EXCEPT 
       ![I].v_p[i_p(I)] = [v |-> divisors(in(I), v_p(I), I, i_p(I)), r |-> 0] ]
  /\ im' = [im EXCEPT 
       ![I] = step(i_p(I))]             
\*  /\ PrintT("P" \o ToString(I \o <<i_p(I)>>) \o " : " \o ToString(v_p(I)[i_p(I)].v')) 


(* 
   Consumer action
   
   FXML:  forall i \in Dom(p) 
            c[i] = notDivides N p[i] 

   PCR:   c = consume notDivides N
*) 
C(I) == 
  \E i \in iterator(I) :
    /\ written(v_p(I), i)
    /\ ~ written(v_c(I), i)
    /\ cm' = [cm EXCEPT 
         ![I].v_p[i].r = @ + 1,
         ![I].v_c[i]   = [v |-> notDivides(in(I), v_p(I), I, i), r |-> 0] ]               
\*    /\ PrintT("C" \o ToString(I \o <<i>>) \o " : P" \o ToString(i) 
\*                  \o " con v=" \o ToString(v_p(I)[i].v))       

(* 
   Reducer action
   
   FXML:  ...

   PCR:   c = reduce and (N > 1) c
*)
R(I) == 
  \E i \in iterator(I) :
    /\ written(v_c(I), i)
    /\ pending(I, i)
    /\ LET newOut == and(in(I), out(I), v_c(I), I, i)
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
   PCR IsPrimeSeq step at index I 
*)      
Next(I) == 
  \/ /\ state(I) = "OFF"
     /\ Start(I)
     /\ UNCHANGED im
  \/ /\ state(I) = "RUN"
     /\ \/ P(I) 
        \/ C(I)      /\ UNCHANGED im 
        \/ R(I)      /\ UNCHANGED im    
        \/ Quit(I)   /\ UNCHANGED im 

=============================================================================
\* Modification History
\* Last modified Tue Dec 15 20:56:28 UYT 2020 by josedu
\* Last modified Fri Jul 17 16:29:48 UYT 2020 by josed
\* Created Mon Jul 06 13:22:55 UYT 2020 by josed
