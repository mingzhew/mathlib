/-
Copyright (c) 2021 Aaron Anderson. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aaron Anderson
-/

import algebra.group.conj_finite
import group_theory.perm.fin
import group_theory.subgroup.simple
import tactic.interval_cases

/-!
# Alternating Groups

The alternating group on a finite type `α` is the subgroup of the permutation group `perm α`
consisting of the even permutations.

## Main definitions

* `alternating_group α` is the alternating group on `α`, defined as a `subgroup (perm α)`.

## Main results
* `two_mul_card_alternating_group` shows that the alternating group is half as large as
  the permutation group it is a subgroup of.

* `closure_three_cycles_eq_alternating` shows that the alternating group is
  generated by 3-cycles.

* `alternating_group.is_simple_group_five` shows that the alternating group on `fin 5` is simple.
  The proof shows that the normal closure of any non-identity element of this group contains a
  3-cycle.

## Tags
alternating group permutation


## TODO
* Show that `alternating_group α` is simple if and only if `fintype.card α ≠ 4`.

-/

open equiv equiv.perm subgroup fintype
variables (α : Type*) [fintype α] [decidable_eq α]

/-- The alternating group on a finite type, realized as a subgroup of `equiv.perm`.
  For $A_n$, use `alternating_group (fin n)`. -/
@[derive fintype] def alternating_group : subgroup (perm α) :=
sign.ker

instance [subsingleton α] : unique (alternating_group α) :=
⟨⟨1⟩, λ ⟨p, hp⟩, subtype.eq (subsingleton.elim p _)⟩

variables {α}

lemma alternating_group_eq_sign_ker : alternating_group α = sign.ker := rfl

namespace equiv.perm

@[simp]
lemma mem_alternating_group {f : perm α} :
  f ∈ alternating_group α ↔ sign f = 1 :=
sign.mem_ker

lemma prod_list_swap_mem_alternating_group_iff_even_length {l : list (perm α)}
  (hl : ∀ g ∈ l, is_swap g) :
  l.prod ∈ alternating_group α ↔ even l.length :=
begin
  rw [mem_alternating_group, sign_prod_list_swap hl, ← units.coe_eq_one, units.coe_pow,
    units.coe_neg_one, neg_one_pow_eq_one_iff_even],
  dec_trivial
end

lemma is_three_cycle.mem_alternating_group {f : perm α} (h : is_three_cycle f) :
  f ∈ alternating_group α :=
mem_alternating_group.2 h.sign

lemma fin_rotate_bit1_mem_alternating_group {n : ℕ} :
  fin_rotate (bit1 n) ∈ alternating_group (fin (bit1 n)) :=
by rw [mem_alternating_group, bit1, sign_fin_rotate, pow_bit0', int.units_mul_self, one_pow]

end equiv.perm

lemma two_mul_card_alternating_group [nontrivial α] :
  2 * card (alternating_group α) = card (perm α) :=
begin
  let := (quotient_group.quotient_ker_equiv_of_surjective _ (sign_surjective α)).to_equiv,
  rw [←fintype.card_units_int, ←fintype.card_congr this],
  exact (subgroup.card_eq_card_quotient_mul_card_subgroup _).symm,
end

namespace alternating_group
open equiv.perm

instance normal : (alternating_group α).normal := sign.normal_ker

lemma is_conj_of {σ τ : alternating_group α}
  (hc : is_conj (σ : perm α) (τ : perm α)) (hσ : (σ : perm α).support.card + 2 ≤ fintype.card α) :
  is_conj σ τ :=
begin
  obtain ⟨σ, hσ⟩ := σ,
  obtain ⟨τ, hτ⟩ := τ,
  obtain ⟨π, hπ⟩ := is_conj_iff.1 hc,
  rw [subtype.coe_mk, subtype.coe_mk] at hπ,
  cases int.units_eq_one_or (sign π) with h h,
  { rw is_conj_iff,
    refine ⟨⟨π, mem_alternating_group.mp h⟩, subtype.val_injective _⟩,
    simpa only [subtype.val_eq_coe, subgroup.coe_mul, coe_inv, coe_mk] using hπ },
  { have h2 : 2 ≤ σ.supportᶜ.card,
    { rw [finset.card_compl, le_tsub_iff_left σ.support.card_le_univ],
      exact hσ },
    obtain ⟨a, ha, b, hb, ab⟩ := finset.one_lt_card.1 h2,
    refine is_conj_iff.2 ⟨⟨π * swap a b, _⟩, subtype.val_injective _⟩,
    { rw [mem_alternating_group, monoid_hom.map_mul, h, sign_swap ab, int.units_mul_self] },
    { simp only [←hπ, coe_mk, subgroup.coe_mul, subtype.val_eq_coe],
      have hd : disjoint (swap a b) σ,
      { rw [disjoint_iff_disjoint_support, support_swap ab, finset.disjoint_insert_left,
          finset.disjoint_singleton_left],
        exact ⟨finset.mem_compl.1 ha, finset.mem_compl.1 hb⟩ },
      rw [mul_assoc π _ σ, hd.commute.eq, coe_inv, coe_mk],
      simp [mul_assoc] } }
end

lemma is_three_cycle_is_conj (h5 : 5 ≤ fintype.card α)
  {σ τ : alternating_group α}
  (hσ : is_three_cycle (σ : perm α)) (hτ : is_three_cycle (τ : perm α)) :
  is_conj σ τ :=
alternating_group.is_conj_of (is_conj_iff_cycle_type_eq.2 (hσ.trans hτ.symm))
  (by rwa hσ.card_support)

end alternating_group

namespace equiv.perm
open alternating_group

@[simp]
theorem closure_three_cycles_eq_alternating :
  closure {σ : perm α | is_three_cycle σ} = alternating_group α :=
closure_eq_of_le _ (λ σ hσ, mem_alternating_group.2 hσ.sign) $ λ σ hσ, begin
  suffices hind : ∀ (n : ℕ) (l : list (perm α)) (hl : ∀ g, g ∈ l → is_swap g)
    (hn : l.length = 2 * n), l.prod ∈ closure {σ : perm α | is_three_cycle σ},
  { obtain ⟨l, rfl, hl⟩ := trunc_swap_factors σ,
    obtain ⟨n, hn⟩ := (prod_list_swap_mem_alternating_group_iff_even_length hl).1 hσ,
    rw ← two_mul at hn,
    exact hind n l hl hn },
  intro n,
  induction n with n ih; intros l hl hn,
  { simp [list.length_eq_zero.1 hn, one_mem] },
  rw [nat.mul_succ] at hn,
  obtain ⟨a, l, rfl⟩ := l.exists_of_length_succ hn,
  rw [list.length_cons, nat.succ_inj'] at hn,
  obtain ⟨b, l, rfl⟩ := l.exists_of_length_succ hn,
  rw [list.prod_cons, list.prod_cons, ← mul_assoc],
  rw [list.length_cons, nat.succ_inj'] at hn,
  exact mul_mem (is_swap.mul_mem_closure_three_cycles (hl a (list.mem_cons_self a _))
    (hl b (list.mem_cons_of_mem a (l.mem_cons_self b))))
    (ih _ (λ g hg, hl g (list.mem_cons_of_mem _ (list.mem_cons_of_mem _ hg))) hn),
end

/-- A key lemma to prove $A_5$ is simple. Shows that any normal subgroup of an alternating group on
  at least 5 elements is the entire alternating group if it contains a 3-cycle. -/
lemma is_three_cycle.alternating_normal_closure (h5 : 5 ≤ fintype.card α)
  {f : perm α} (hf : is_three_cycle f) :
  normal_closure ({⟨f, hf.mem_alternating_group⟩} : set (alternating_group α)) = ⊤ :=
eq_top_iff.2 begin
  have hi : function.injective (alternating_group α).subtype := subtype.coe_injective,
  refine eq_top_iff.1 (map_injective hi (le_antisymm (map_mono le_top) _)),
  rw [← monoid_hom.range_eq_map, subtype_range, normal_closure, monoid_hom.map_closure],
  refine (le_of_eq closure_three_cycles_eq_alternating.symm).trans (closure_mono _),
  intros g h,
  obtain ⟨c, rfl⟩ := is_conj_iff.1 (is_conj_iff_cycle_type_eq.2 (hf.trans h.symm)),
  refine ⟨⟨c * f * c⁻¹, h.mem_alternating_group⟩, _, rfl⟩,
  rw group.mem_conjugates_of_set_iff,
  exact ⟨⟨f, hf.mem_alternating_group⟩, set.mem_singleton _, is_three_cycle_is_conj h5 hf h⟩
end

/-- Part of proving $A_5$ is simple. Shows that the square of any element of $A_5$ with a 3-cycle in
  its cycle decomposition is a 3-cycle, so the normal closure of the original element must be
  $A_5$. -/
lemma is_three_cycle_sq_of_three_mem_cycle_type_five {g : perm (fin 5)} (h : 3 ∈ cycle_type g) :
  is_three_cycle (g * g) :=
begin
  obtain ⟨c, g', rfl, hd, hc, h3⟩ := mem_cycle_type_iff.1 h,
  simp only [mul_assoc],
  rw [hd.commute.eq, ← mul_assoc g'],
  suffices hg' : order_of g' ∣ 2,
  { rw [← pow_two, order_of_dvd_iff_pow_eq_one.1 hg', one_mul],
    exact (card_support_eq_three_iff.1 h3).is_three_cycle_sq },
  rw [← lcm_cycle_type, multiset.lcm_dvd],
  intros n hn,
  rw le_antisymm (two_le_of_mem_cycle_type hn) (le_trans (le_card_support_of_mem_cycle_type hn) _),
  apply le_of_add_le_add_left,
  rw [← hd.card_support_mul, h3],
  exact (c * g').support.card_le_univ,
end

end equiv.perm

namespace alternating_group
open equiv.perm

lemma nontrivial_of_three_le_card (h3 : 3 ≤ card α) : nontrivial (alternating_group α) :=
begin
  haveI := fintype.one_lt_card_iff_nontrivial.1 (lt_trans dec_trivial h3),
  rw ← fintype.one_lt_card_iff_nontrivial,
  refine lt_of_mul_lt_mul_left _ (le_of_lt nat.prime_two.pos),
  rw [two_mul_card_alternating_group, card_perm, ← nat.succ_le_iff],
  exact le_trans h3 (card α).self_le_factorial,
end

instance {n : ℕ} : nontrivial (alternating_group (fin (n + 3))) :=
nontrivial_of_three_le_card (by { rw card_fin, exact le_add_left (le_refl 3) })

/-- The normal closure of the 5-cycle `fin_rotate 5` within $A_5$ is the whole group. This will be
  used to show that the normal closure of any 5-cycle within $A_5$ is the whole group. -/
lemma normal_closure_fin_rotate_five :
  (normal_closure ({⟨fin_rotate 5, fin_rotate_bit1_mem_alternating_group⟩} :
    set (alternating_group (fin 5)))) = ⊤ :=
eq_top_iff.2 begin
  have h3 : is_three_cycle ((fin.cycle_range 2) * (fin_rotate 5) *
    (fin.cycle_range 2)⁻¹ * (fin_rotate 5)⁻¹) := card_support_eq_three_iff.1 dec_trivial,
  rw ← h3.alternating_normal_closure (by rw [card_fin]),
  refine normal_closure_le_normal _,
  rw [set.singleton_subset_iff, set_like.mem_coe],
  have h : (⟨fin_rotate 5, fin_rotate_bit1_mem_alternating_group⟩ :
    alternating_group (fin 5)) ∈ normal_closure _ :=
    set_like.mem_coe.1 (subset_normal_closure (set.mem_singleton _)),
  exact mul_mem (subgroup.normal_closure_normal.conj_mem _ h
    ⟨fin.cycle_range 2, fin.is_three_cycle_cycle_range_two.mem_alternating_group⟩) (inv_mem h),
end

/-- The normal closure of $(04)(13)$ within $A_5$ is the whole group. This will be
  used to show that the normal closure of any permutation of cycle type $(2,2)$ is the whole group.
  -/
lemma normal_closure_swap_mul_swap_five :
  (normal_closure ({⟨swap 0 4 * swap 1 3, mem_alternating_group.2 dec_trivial⟩} :
    set (alternating_group (fin 5)))) = ⊤ :=
begin
  let g1 := (⟨swap 0 2 * swap 0 1, mem_alternating_group.2 dec_trivial⟩ :
    alternating_group (fin 5)),
  let g2 := (⟨swap 0 4 * swap 1 3, mem_alternating_group.2 dec_trivial⟩ :
    alternating_group (fin 5)),
  have h5 : g1 * g2 * g1⁻¹ * g2⁻¹ = ⟨fin_rotate 5, fin_rotate_bit1_mem_alternating_group⟩,
  { rw subtype.ext_iff,
    simp only [fin.coe_mk, subgroup.coe_mul, subgroup.coe_inv, fin.coe_mk],
    dec_trivial },
  rw [eq_top_iff, ← normal_closure_fin_rotate_five],
  refine normal_closure_le_normal _,
  rw [set.singleton_subset_iff, set_like.mem_coe, ← h5],
  have h : g2 ∈ normal_closure {g2} :=
    set_like.mem_coe.1 (subset_normal_closure (set.mem_singleton _)),
  exact mul_mem (subgroup.normal_closure_normal.conj_mem _ h g1) (inv_mem h),
end

/-- Shows that any non-identity element of $A_5$ whose cycle decomposition consists only of swaps
  is conjugate to $(04)(13)$. This is used to show that the normal closure of such a permutation
  in $A_5$ is $A_5$. -/
lemma is_conj_swap_mul_swap_of_cycle_type_two {g : perm (fin 5)}
  (ha : g ∈ alternating_group (fin 5))
  (h1 : g ≠ 1)
  (h2 : ∀ n, n ∈ cycle_type (g : perm (fin 5)) → n = 2) :
  is_conj (swap 0 4 * swap 1 3) g :=
begin
  have h := g.support.card_le_univ,
  rw [← multiset.eq_replicate_card] at h2,
  rw [← sum_cycle_type, h2, multiset.sum_replicate, smul_eq_mul] at h,
  have h : g.cycle_type.card ≤ 3 := le_of_mul_le_mul_right (le_trans h dec_trivial) dec_trivial,
  rw [mem_alternating_group, sign_of_cycle_type, h2] at ha,
  norm_num at ha,
  rw [pow_add, pow_mul, int.units_pow_two,one_mul,
      units.ext_iff, units.coe_one, units.coe_pow, units.coe_neg_one,
      neg_one_pow_eq_one_iff_even _] at ha,
  swap, { dec_trivial },
  rw [is_conj_iff_cycle_type_eq, h2],
  interval_cases multiset.card g.cycle_type,
  { exact (h1 (card_cycle_type_eq_zero.1 h_1)).elim },
  { contrapose! ha,
    simp [h_1] },
  { have h04 : (0 : fin 5) ≠ 4 := dec_trivial,
    have h13 : (1 : fin 5) ≠ 3 := dec_trivial,
    rw [h_1, disjoint.cycle_type, (is_cycle_swap h04).cycle_type, (is_cycle_swap h13).cycle_type,
      card_support_swap h04, card_support_swap h13],
    { refl },
    { rw [disjoint_iff_disjoint_support, support_swap h04, support_swap h13],
      dec_trivial } },
  { contrapose! ha,
    simp [h_1] }
end

/-- Shows that $A_5$ is simple by taking an arbitrary non-identity element and showing by casework
  on its cycle type that its normal closure is all of $A_5$.   -/
instance is_simple_group_five : is_simple_group (alternating_group (fin 5)) :=
⟨exists_pair_ne _, λ H, begin
  introI Hn,
  refine or_not.imp (id) (λ Hb, _),
  rw [eq_bot_iff_forall] at Hb,
  push_neg at Hb,
  obtain ⟨⟨g, gA⟩, gH, g1⟩ : ∃ (x : ↥(alternating_group (fin 5))), x ∈ H ∧ x ≠ 1 := Hb,
  -- `g` is a non-identity alternating permutation in a normal subgroup `H` of $A_5$.
  rw [← set_like.mem_coe, ← set.singleton_subset_iff] at gH,
  refine eq_top_iff.2 (le_trans (ge_of_eq _) (normal_closure_le_normal gH)),
  -- It suffices to show that the normal closure of `g` in $A_5$ is $A_5$.
  by_cases h2 : ∀ n ∈ g.cycle_type, n = 2,
  { -- If the cycle decomposition of `g` consists entirely of swaps, then the cycle type is $(2,2)$.
    -- This means that it is conjugate to $(04)(13)$, whose normal closure is $A_5$.
    rw [ne.def, subtype.ext_iff] at g1,
    exact (is_conj_swap_mul_swap_of_cycle_type_two gA g1 h2).normal_closure_eq_top_of
      normal_closure_swap_mul_swap_five },
  push_neg at h2,
  obtain ⟨n, ng, n2⟩ : ∃ (n : ℕ), n ∈ g.cycle_type ∧ n ≠ 2 := h2,
  -- `n` is the size of a non-swap cycle in the decomposition of `g`.
  have n2' : 2 < n := lt_of_le_of_ne (two_le_of_mem_cycle_type ng) n2.symm,
  have n5 : n ≤ 5 := le_trans _ g.support.card_le_univ,
  -- We check that `2 < n ≤ 5`, so that `interval_cases` has a precise range to check.
  swap, { obtain ⟨m, hm⟩ := multiset.exists_cons_of_mem ng,
    rw [← sum_cycle_type, hm, multiset.sum_cons],
    exact le_add_right le_rfl },
  interval_cases n, -- This breaks into cases `n = 3`, `n = 4`, `n = 5`.
  { -- If `n = 3`, then `g` has a 3-cycle in its decomposition, so `g^2` is a 3-cycle.
    -- `g^2` is in the normal closure of `g`, so that normal closure must be $A_5$.
    rw [eq_top_iff, ← (is_three_cycle_sq_of_three_mem_cycle_type_five ng).alternating_normal_closure
      (by rw card_fin )],
    refine normal_closure_le_normal _,
    rw [set.singleton_subset_iff, set_like.mem_coe],
    have h := set_like.mem_coe.1 (subset_normal_closure (set.mem_singleton _)),
    exact mul_mem h h },
  { -- The case `n = 4` leads to contradiction, as no element of $A_5$ includes a 4-cycle.
    have con := mem_alternating_group.1 gA,
    contrapose! con,
    rw [sign_of_cycle_type,
      cycle_type_of_card_le_mem_cycle_type_add_two dec_trivial ng],
    dec_trivial },
  { -- If `n = 5`, then `g` is itself a 5-cycle, conjugate to `fin_rotate 5`.
    refine (is_conj_iff_cycle_type_eq.2 _).normal_closure_eq_top_of
      normal_closure_fin_rotate_five,
    rw [cycle_type_of_card_le_mem_cycle_type_add_two dec_trivial ng, cycle_type_fin_rotate] }
end⟩

end alternating_group