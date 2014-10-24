(* -*- mode: coq; mode: visual-line -*- *)
(** * Comparing definitions of equivalence *)

Require Import HoTT.Basics HoTT.Types.
Require Import HProp.
Require Import HoTT.Tactics.
Local Open Scope path_scope.
Local Open Scope equiv_scope.

Generalizable Variables A B f.

Section AssumeFunext.
Context `{Funext}.

(** In this file we show that several different definitions of "equivalence" are all equivalent to the one we have chosen.  This also yields alternative proofs that [IsEquiv f] is an hprop. *)

(** ** Contractible maps *)

(** We say a map is "contractible" if all of its homotopy fibers are contractible.  (More generally, a map is n-truncated if all of its homotopy fibers are n-truncated.)  This was Voevodsky's first definition of equivalences in homotopy type theory.

   It is fairly straightforward to show that this definition is *logically* equivalent to the one we have given.
*)

Definition fcontr_isequiv `(f : A -> B)
  : IsEquiv f -> (forall b:B, Contr {a : A & f a = b}).
Proof.
  intros ? b.  exists (f^-1 b ; eisretr f b).  intros [a p].
  refine (path_sigma' _ ((ap f^-1 p)^ @ eissect f a) _).
  rewrite (transport_compose (fun y => y = b) f _ _), transport_paths_l.
  rewrite ap_pp, ap_V, <- ap_compose, inv_Vp, concat_pp_p.
  unfold compose; rewrite (concat_A1p (eisretr f) p).
  rewrite eisadj.  by apply concat_V_pp.
Defined.

Definition isequiv_fcontr `(f : A -> B)
  : (forall b:B, Contr {a : A & f a = b}) -> IsEquiv f.
Proof.
  intros ?. refine (BuildIsEquiv _ _ _
    (fun b => (center {a : A & f a = b}).1)
    (fun b => (center {a : A & f a = b}).2)
    (fun a => (@contr {x : A & f x = f a} _ (a;1))..1)
    _).
  intros a. apply moveL_M1.
  rewrite <- transport_paths_l, <- transport_compose.
  exact ((@contr {x : A & f x = f a} _ (a;1))..2).
Defined.

(** Therefore, since both are hprops, they are equivalent by [equiv_iff_hprop].  However, we can also use this to *prove* that [IsEquiv] is an hprop.  We begin by showing that if [f] is an equivalence, then the type of sections of [f] and the type of retractions of [f] are both contractible. *)

Definition contr_sect_equiv `(f : A -> B) `{IsEquiv A B f}
  : Contr {g : B -> A & Sect g f}.
Proof.
  (* First we turn homotopies into paths. *)
  refine (contr_equiv' { g : B -> A & f o g = idmap } _).
  symmetry.
  refine (equiv_functor_sigma' (equiv_idmap _) _); intros g.
  exact (equiv_path_forall (f o g) idmap).
  (* Now this is just the fiber over [idmap] of postcomposition with [f], and the latter is an equivalence since [f] is. *)
  apply fcontr_isequiv; exact _.
Defined.

Definition contr_retr_equiv `(f : A -> B) `{IsEquiv A B f}
  : Contr {g : B -> A & Sect f g}.
Proof.
  (* This proof is just like the previous one. *)
  refine (contr_equiv' { g : B -> A & g o f = idmap } _).
  symmetry.
  refine (equiv_functor_sigma' (equiv_idmap _) _); intros g.
  exact (equiv_path_forall (g o f) idmap).
  apply fcontr_isequiv; exact _.
Defined.

(** Using this, we can prove that [IsEquiv f] is an h-proposition.  We make this a [Local Instance] since we already have a [Global Instance] of it available in [types/Universe].  *)

Local Instance hprop_isequiv `(f : A -> B) : IsHProp (IsEquiv f).
Proof.
  apply hprop_inhabited_contr; intros ?.
  (* Get rid of that pesky record. *)
  refine (contr_equiv _ (issig_isequiv f)).
  (* Now we claim that the top two elements, [s] and the coherence relation, taken together are contractible, so we can peel them off. *)
  refine (contr_equiv' {g : B -> A & Sect g f}
    (equiv_inverse (equiv_functor_sigma' (equiv_idmap (B -> A))
      (fun g => (@equiv_sigma_contr (Sect g f)
        (fun r => {s : Sect f g & forall x, r (f x) = ap f (s x) })
        _))))).
  (* What remains afterwards is just the type of sections of [f]. *)
  2:apply contr_sect_equiv; assumption.
  intros r.
  (* Now we claim this is equivalent to a certain space of paths. *)
  refine (contr_equiv'
    (forall x, (existT (fun a => f a = f x) x 1) = (g (f x); r (f x)))
    (equiv_inverse _)).
  (* The proof of this equivalence is basically just rearranging quantifiers and paths. *)
  refine (equiv_compose' _ (equiv_sigT_coind (fun x => g (f x) = x)
      (fun x p => r (f x) = ap f p))).
  refine (equiv_functor_forall' (equiv_idmap A) _); intros a; simpl.
  refine (equiv_compose' (equiv_path_inverse _ _) _).
  refine (equiv_compose' (equiv_path_sigma (fun x => f x = f a)
    (g (f a) ; r (f a)) (a ; 1)) _); simpl.
  refine (equiv_functor_sigma' (equiv_idmap _) _); intros p; simpl.
  rewrite (transport_compose (fun y => y = f a) f), transport_paths_l.
  refine (equiv_compose' (equiv_moveR_Vp _ _ _) _).
  by rewrite concat_p1; apply equiv_idmap.
  (* Finally, this is a space of paths in a fiber of [f]. *)
  refine (@contr_forall _ _ _ _); intros a.
  refine (@contr_paths_contr _ _ _ _).
  by refine (fcontr_isequiv f _ _).
Qed.

(** Now since [IsEquiv f] and the assertion that its fibers are contractible are both HProps, logical equivalence implies equivalence. *)

Definition equiv_fcontr_isequiv `(f : A -> B)
  : (forall b:B, Contr {a : A & f a = b}) <~> IsEquiv f.
Proof.
  apply equiv_iff_hprop.
  by apply isequiv_fcontr.
  by apply fcontr_isequiv.
Defined.

(** Alternatively, we could also construct this equivalence directly, and derive the fact that [IsEquiv f] is an HProp from that.  *)

Local Definition equiv_fcontr_isequiv' `(f : A -> B)
  : (forall b:B, Contr {a : A & f a = b}) <~> IsEquiv f.
Proof.
  (* First we get rid of those pesky records. *)
  refine (equiv_compose' _ (equiv_functor_forall idmap
    (fun b => equiv_inverse (issig_contr {a : A & f a = b})))).
  refine (equiv_compose' (issig_isequiv f) _).
  (* Now we can really get to work.
     First we peel off the inverse function and the [eisretr]. *)
  refine (equiv_compose' _ (equiv_inverse (equiv_sigT_coind _ _))).
  refine (equiv_compose' _ (equiv_inverse
    (@equiv_functor_sigma' _ _ _ (fun f0 => forall x y, f0 x = y)
      (equiv_sigT_coind _ _)
      (fun fg => equiv_idmap (forall x y,
        (equiv_sigT_coind _ (fun b a => f a = b) fg x = y)))))).
  refine (equiv_compose' _ (equiv_inverse (equiv_sigma_assoc
    (fun g => forall x, f (g x) = x)
    (fun gh => forall x y,
      (fun b => (gh.1 b; gh.2 b)) x = y)))).
  refine (equiv_functor_sigma' (equiv_idmap _) _). intros g.
  refine (equiv_functor_sigma' (equiv_idmap _) _). intros r. simpl.
  (* Now we use the fact that Paulin-Mohring J is an equivalence. *)
  refine (equiv_compose' _ (equiv_inverse (@equiv_functor_forall' _ _
    (fun x => forall a (y : f a = x),
      (existT (fun a => f a = x) (g x) (r x)) = (a;y))
    _ _ (equiv_idmap _)
    (fun x:B => equiv_sigT_ind
      (fun y:exists a:A, f a = x => (g x;r x) = y))))).
  refine (equiv_compose' _ (equiv_flip _)).
  refine (equiv_compose' _ (equiv_inverse (@equiv_functor_forall' _ _
    (fun a => existT (fun a' => f a' = f a) (g (f a)) (r (f a)) = (a;1))
    _ _ (equiv_idmap A)
    (fun a => equiv_paths_ind (f a)
      (fun b y => (existT (fun a => f a = b) (g b) (r b)) = (a;y)))))).
  (* We identify the paths in a Sigma-type. *)
  refine (equiv_compose' _ (equiv_inverse (@equiv_functor_forall' _ _
    (fun a =>
      exists p, transport (fun a' : A => f a' = f a) p (r (f a)) = 1)
    _ _ (equiv_idmap A)
    (fun a => equiv_path_sigma (fun a' => f a' = f a)
      (g (f a);r (f a)) (a;1))))).
  (* Now we can peel off the [eissect]. *)
  refine (equiv_compose' _ (equiv_inverse (equiv_sigT_coind
    (fun a => g (f a) = a)
    (fun a p => transport (fun a' => f a' = f a) p (r (f a)) = 1)))).
  refine (equiv_functor_sigma' (equiv_idmap _) _). intros s.
  (* And what's left is the [eisadj]. *)
  refine (equiv_functor_forall' (equiv_idmap _) _). intros a; simpl.
  refine (equiv_compose' _ (equiv_concat_l
             (transport_compose (fun b => b = f a) f (s a) (r (f a))
              @ transport_paths_l (ap f (s a)) (r (f a)))^ 1)).
  exact (equiv_compose'
    (equiv_concat_r (concat_p1 _) _)
    (equiv_inverse (equiv_moveR_Vp (r (f a)) 1 (ap f (s a))))).
Defined.

(** ** Bi-invertible maps *)

(** A map is "bi-invertible" if it has both a section and a retraction, not necessarily the same.  This definition of equivalence was proposed by Andre Joyal. *)

Definition BiInv `(f : A -> B) : Type
  := {g : B -> A & Sect f g} * {h : B -> A & Sect h f}.

(** It seems that the easiest way to show that bi-invertibility is equivalent to being an equivalence is also to show that both are h-props and that they are logically equivalent. *)

Definition isequiv_biinv `(f : A -> B)
  : BiInv f -> IsEquiv f.
Proof.
  intros [[g s] [h r]].
  exact (isequiv_adjointify f g
    (fun x => ap f (ap g (r x)^ @ s (h x))  @ r x)
    s).
Defined.

Global Instance isprop_biinv `(f : A -> B) : IsHProp (BiInv f) | 0.
Proof.
  apply hprop_inhabited_contr.
  intros bif; pose (fe := isequiv_biinv f bif).
  apply @contr_prod.
  (* For this, we've done all the work already. *)
  by apply contr_retr_equiv.
  by apply contr_sect_equiv.
Defined.

Definition equiv_biinv_isequiv `(f : A -> B)
  : BiInv f <~> IsEquiv f.
Proof.
  apply equiv_iff_hprop.
  by apply isequiv_biinv.
  intros ?.  split.
  by exists (f^-1); apply eissect.
  by exists (f^-1); apply eisretr.
Defined.

(** ** n-Path-split maps.
 
A map is n-path-split if its induced maps on the first n iterated path-spaces are split surjections.  Thus every map is 0-path-split, the 1-path-split maps are the split surjections, and so on.  It turns out that being n-path-split for n>1 is the same as being an equivalence. *)

Fixpoint PathSplit (n : nat) `(f : A -> B) : Type
  := match n with
       | 0 => Unit
       | S n => {g : B -> A & Sect g f} *
                forall (x y : A), PathSplit n (@ap _ _ f x y)
     end.

Definition isequiv_pathsplit (n : nat) `{f : A -> B}
: PathSplit n.+2 f -> IsEquiv f.
Proof.
  intros [[g sg] k].
  pose (h := fun x y => (fst (k x y)).1).
  pose (hs := fun x y => (fst (k x y)).2 : Sect (h x y) (ap f)).
  clearbody hs; clearbody h; clear k.
  apply isequiv_fcontr; intros b.
  apply contr_inhabited_hprop.
  2:exact (g b ; sg b).
  apply hprop_allpath; intros [a p] [a' p'].
  refine (path_sigma' _ (h a a' (p @ p'^)) _).
  refine (transport_paths_Fl _ _ @ _).
  refine ((inverse2 (hs a a' (p @ p'^)) @@ 1) @ _).
  refine ((inv_pp p p'^ @@ 1) @ _).
  refine (concat_pp_p _ _ _ @ _).
  refine ((1 @@ concat_Vp _) @ _).
  exact ((inv_V p' @@ 1) @ concat_p1 _).
Defined.

Global Instance contr_pathsplit_isequiv
           (n : nat) `(f : A -> B) `{IsEquiv _ _ f}
: Contr (PathSplit n f).
Proof.
  generalize dependent B; revert A.
  induction n as [ | n IHn]; intros A B f ?.
  - exact _.
  - refine contr_prod.
    exact (contr_sect_equiv f).
Defined.
      
Global Instance ishprop_pathsplit (n : nat) `(f : A -> B)
: IsHProp (PathSplit n.+2 f).
Proof.
  apply hprop_inhabited_contr; intros ps.
  pose (isequiv_pathsplit n ps).
  exact _.
Defined.

Definition equiv_pathsplit_isequiv (n : nat) `(f : A -> B)
: PathSplit n.+2 f <~> IsEquiv f.
Proof.
  refine (equiv_iff_hprop _ _).
  - apply isequiv_pathsplit.
  - intros ?; refine (center _).
Defined.

(** A map is oo-path-split if it is n-path-split for all n.  This is also equivalent to being an equivalence. *)

Definition ooPathSplit `(f : A -> B) : Type
  := forall n, PathSplit n f.

Definition isequiv_oopathsplit `{f : A -> B}
: ooPathSplit f -> IsEquiv f
  := fun ps => isequiv_pathsplit 0 (ps 2).

Global Instance contr_oopathsplit_isequiv
           `(f : A -> B) `{IsEquiv _ _ f}
: Contr (ooPathSplit f).
Proof.
  apply contr_forall.
Defined.

Global Instance ishprop_oopathsplit `(f : A -> B)
: IsHProp (ooPathSplit f).
Proof.
  apply hprop_inhabited_contr; intros ps.
  pose (isequiv_oopathsplit ps).
  exact _.
Defined.

Definition equiv_oopathsplit_isequiv `(f : A -> B)
: ooPathSplit f <~> IsEquiv f.
Proof.
  refine (equiv_iff_hprop _ _).
  - apply isequiv_oopathsplit.
  - intros ?; refine (center _).
Defined.

(** ** Pointwise path-split maps *)

(** A nice thing about path-splitness is that when considering precomposition equivalences, we can define a version of it using only pointwise paths.  This often avoids the need to introduce funext redexes.

Is there a more concise name for this type?  I haven't been able to think of any way to abbreviate it recognizably. *)

Fixpoint Pointwise_PathSplit_Precompose
         (n : nat) {A B : Type} (C : B -> Type) (f : A -> B) : Type
  := match n with
       | 0 => Unit
       | S n => {rec : (forall a, C (f a)) -> (forall b, C b) &
                     forall (g : forall a, C (f a)), rec g oD f == g } *
                forall (h k : forall b, C b),
                  Pointwise_PathSplit_Precompose n (fun b => h b = k b) f
     end.

(* We'll need this lemma in a moment. *)
Lemma equiv_functor_pathsplit (n : nat) {A B C D}
      (f : A -> B) (g : C -> D) (h : A <~> C) (k : B <~> D)
      (p : g o h == k o f)
: PathSplit n f <~> PathSplit n g.
Proof.
  destruct n as [|n].
  1:apply equiv_idmap.
  destruct n as [|n].
  - simpl.
    apply equiv_functor_prod'.
    2:apply equiv_contr_contr.
    refine (equiv_functor_sigma'
              (equiv_compose' (equiv_precompose (equiv_inverse k))
                              (equiv_postcompose h)) _);
      intros fi; simpl; unfold compose, Sect.
    refine (equiv_functor_forall' (equiv_inverse k) _); intros d.
    refine (equiv_compose' (equiv_concat_l (p (fi (k^-1 d))) d) _).
    unfold compose; simpl; apply equiv_moveR_equiv_M.
  - refine (equiv_compose' _ (equiv_pathsplit_isequiv n f)).
    refine (equiv_compose' (equiv_inverse (equiv_pathsplit_isequiv n g)) _).
    apply equiv_iff_hprop; intros e.
    + refine (isequiv_commsq f g h k (fun a => (p a)^)).
    + refine (isequiv_commsq' f g h k p).
Defined.

Definition equiv_pointwise_pathsplit (n : nat)
           {A B : Type} (C : B -> Type) (f : A -> B)
: Pointwise_PathSplit_Precompose n C f
  <~> PathSplit n (fun (g : forall b, C b) => g oD f).
Proof.
  generalize dependent C; induction n as [ | n IHn]; intros C.
  1:apply equiv_idmap.
  apply equiv_functor_prod'; simpl.
  - refine (equiv_functor_sigma' (equiv_idmap _) _); intros rec.
    refine (equiv_functor_forall' (equiv_idmap _) _); intros g; simpl.
    apply equiv_path_forall.
  - refine (equiv_functor_forall' (equiv_idmap _) _); intros h.
    refine (equiv_functor_forall' (equiv_idmap _) _); intros k; simpl.
    refine (equiv_compose' _ (IHn (fun b => h b = k b))).
    symmetry; refine (equiv_functor_pathsplit n _ _
                       (equiv_apD10 _ _ _) (equiv_apD10 _ _ _) _).
    intros []; reflexivity.
Defined.

Definition isequiv_pointwise_pathsplit (n : nat)
           {A B : Type} {C : B -> Type} {f : A -> B}
  : Pointwise_PathSplit_Precompose n.+2 C f
    -> IsEquiv (fun g => g oD f)
  := isequiv_pathsplit n o (equiv_pointwise_pathsplit n.+2 C f).

Global Instance ishprop_pointwise_pathsplit (n : nat)
       {A B : Type} (C : B -> Type) (f : A -> B)
: IsHProp (Pointwise_PathSplit_Precompose n.+2 C f).
Proof.
  (* TODO: Why is this so slow? *)
  refine (trunc_equiv _ (equiv_pointwise_pathsplit n.+2 C f)^-1).
Defined.

Definition equiv_pointwise_pathsplit_isequiv (n : nat)
       {A B : Type} (C : B -> Type) (f : A -> B)
: Pointwise_PathSplit_Precompose n.+2 C f
  <~> IsEquiv (fun (g : forall b, C b) => g oD f).
Proof.
  etransitivity.
  - apply equiv_pointwise_pathsplit.
  - apply equiv_pathsplit_isequiv.
Defined.

(** Postcomposition with a known equivalence. *)
Definition pointwise_pathsplit_postcompose' (n : nat)
           {A B : Type} (C D : B -> Type) (f : A -> B)
           (g : forall b, C b <~> D b)
: Pointwise_PathSplit_Precompose n C f
  -> Pointwise_PathSplit_Precompose n D f.
Proof.
  generalize dependent D; revert C.
  induction n as [|n IHn]; intros C D g; simpl.
  1:apply idmap.
  refine (functor_prod _ _).
  - refine (functor_sigma
              (functor_arrow
                 (functor_forall idmap (fun a => (g (f a))^-1))
                 (functor_forall idmap g)) _);
      intros unf; simpl.
    refine (functor_forall (functor_forall idmap
             (fun a => (g (f a))^-1)) _);
      intros h; simpl.
    refine (functor_forall idmap _);
      intros a; unfold functor_arrow, functor_forall, composeD; simpl.
    apply moveR_equiv_M.
  - refine (functor_forall (functor_forall idmap (fun b => (g b)^-1)) _);
      intros h.
    refine (functor_forall (functor_forall idmap (fun b => (g b)^-1)) _);
      intros k; simpl; unfold functor_forall.
    refine (IHn _ _ _); intros b.
    apply equiv_inverse, equiv_ap; exact _.
Defined.

Definition pointwise_pathsplit_postcompose (n : nat)
           {A B : Type} (C D : B -> Type) (f : A -> B)
           (g : forall b, C b -> D b) `{forall b, IsEquiv (g b)}
: Pointwise_PathSplit_Precompose n C f
  -> Pointwise_PathSplit_Precompose n D f
:= pointwise_pathsplit_postcompose' n C D f
     (fun b => BuildEquiv _ _ (g b) _).

(** And the oo-version of pointwise path-split maps. *)

Definition oo_Pointwise_PathSplit_Precompose
           {A B : Type} (C : B -> Type) (f : A -> B) : Type
  := forall n, Pointwise_PathSplit_Precompose n C f.

Definition isequiv_oo_pointwise_pathsplit
           {A B : Type} (C : B -> Type) (f : A -> B)
: oo_Pointwise_PathSplit_Precompose C f
  -> IsEquiv (fun g => g oD f)
  := fun ps => isequiv_pointwise_pathsplit 0 (ps 2).

Definition equiv_oo_pointwise_pathsplit
           {A B : Type} (C : B -> Type) (f : A -> B)
: oo_Pointwise_PathSplit_Precompose C f
  <~> ooPathSplit (fun (g : forall b, C b) => g oD f).
Proof.
  refine (equiv_functor_forall' (equiv_idmap _) _); intros n.
  apply equiv_pointwise_pathsplit.
Defined.

Global Instance ishprop_oo_pointwise_pathsplit
       {A B : Type} (C : B -> Type) (f : A -> B)
: IsHProp (oo_Pointwise_PathSplit_Precompose C f).
Proof.
  refine (trunc_equiv _ (equiv_oo_pointwise_pathsplit C f)^-1).
Defined.

Definition equiv_oo_pointwise_pathsplit_isequiv 
           {A B : Type} (C : B -> Type) (f : A -> B)
: oo_Pointwise_PathSplit_Precompose C f
  <~> IsEquiv (fun (g : forall b, C b) => g oD f).
Proof.
  etransitivity.
  - apply equiv_oo_pointwise_pathsplit.
  - apply equiv_oopathsplit_isequiv.
Defined.

End AssumeFunext.
