/-
Copyright (c) 2021 Andrew Yang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Andrew Yang
-/
import ring_theory.local_properties
import ring_theory.localization.inv_submonoid

/-!

# The meta properties of finite-type ring homomorphisms.

The main result is `ring_hom.finite_is_local`.

-/

namespace ring_hom

open_locale pointwise

lemma finite_type_stable_under_composition :
  stable_under_composition @finite_type :=
by { introv R hf hg, exactI hg.comp hf }

lemma finite_type_holds_for_localization_away :
  holds_for_localization_away @finite_type :=
begin
  introv R _,
  resetI,
  suffices : algebra.finite_type R S,
  { change algebra.finite_type _ _, convert this, ext, rw algebra.smul_def, refl },
  exact is_localization.finite_type_of_monoid_fg (submonoid.powers r) S,
end

lemma finite_type_of_localization_span_target : of_localization_span_target @finite_type :=
begin
  -- Setup algebra intances.
  rw of_localization_span_target_iff_finite,
  introv R hs H,
  resetI,
  classical,
  letI := f.to_algebra,
  replace H : ∀ r : s, algebra.finite_type R (localization.away (r : S)),
  { intro r, convert H r, ext, rw algebra.smul_def, refl },
  replace H := λ r, (H r).1,
  constructor,
  -- Suppose `s : finset S` spans `S`, and each `Sᵣ` is finitely generated as an `R`-algebra.
  -- Say `t r : finset Sᵣ` generates `Sᵣ`. By assumption, we may find `lᵢ` such that
  -- `∑ lᵢ * sᵢ = 1`. I claim that all `s` and `l` and the numerators of `t` and generates `S`.
  choose t ht using H,
  obtain ⟨l, hl⟩ := (finsupp.mem_span_iff_total S (s : set S) 1).mp
    (show (1 : S) ∈ ideal.span (s : set S), by { rw hs, trivial }),
  let sf := λ (x : s), is_localization.finset_integer_multiple (submonoid.powers (x : S)) (t x),
  use s.attach.bUnion sf ∪ s ∪ l.support.image l,
  rw eq_top_iff,
  -- We need to show that every `x` falls in the subalgebra generated by those elements.
  -- Since all `s` and `l` are in the subalgebra, it suffices to check that `sᵢ ^ nᵢ • x` falls in
  -- the algebra for each `sᵢ` and some `nᵢ`.
  rintro x -,
  apply subalgebra.mem_of_span_eq_top_of_smul_pow_mem _ (s : set S) l hl _ _ x _,
  { intros x hx,
    apply algebra.subset_adjoin,
    rw [finset.coe_union, finset.coe_union],
    exact or.inl (or.inr hx) },
  { intros i,
    by_cases h : l i = 0, { rw h, exact zero_mem _ },
    apply algebra.subset_adjoin,
    rw [finset.coe_union, finset.coe_image],
    exact or.inr (set.mem_image_of_mem _ (finsupp.mem_support_iff.mpr h)) },
  { intro r,
    rw [finset.coe_union, finset.coe_union, finset.coe_bUnion],
    -- Since all `sᵢ` and numerators of `t r` are in the algebra, it suffices to show that the
    -- image of `x` in `Sᵣ` falls in the `R`-adjoin of `t r`, which is of course true.
    obtain ⟨⟨_, n₂, rfl⟩, hn₂⟩ := is_localization.exists_smul_mem_of_mem_adjoin
      (submonoid.powers (r : S)) x (t r)
      (algebra.adjoin R _) _ _ _,
    { exact ⟨n₂, hn₂⟩ },
    { intros x hx,
      apply algebra.subset_adjoin,
      refine or.inl (or.inl ⟨_, ⟨r, rfl⟩, _, ⟨s.mem_attach r, rfl⟩, hx⟩) },
    { rw [submonoid.powers_eq_closure, submonoid.closure_le, set.singleton_subset_iff],
      apply algebra.subset_adjoin,
      exact or.inl (or.inr r.2) },
    { rw ht, trivial } }
end

lemma finite_type_is_local :
  property_is_local @finite_type :=
⟨localization_finite_type, finite_type_of_localization_span_target,
  finite_type_stable_under_composition, finite_type_holds_for_localization_away⟩

lemma finite_type_respects_iso : ring_hom.respects_iso @ring_hom.finite_type :=
ring_hom.finite_type_is_local.respects_iso

end ring_hom