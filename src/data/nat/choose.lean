/-
Copyright (c) 2018 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes, Bhavik Mehta, Patrick Stevens
-/
import algebra.commute
import tactic.linarith
import tactic.ring_exp

open nat

open_locale big_operators

lemma nat.prime.dvd_choose {p k : ℕ} (hk : 0 < k) (hkp : k < p) (hp : prime p) : p ∣ choose p k :=
have h₁ : p ∣ fact p, from hp.dvd_fact.2 (le_refl _),
have h₂ : ¬p ∣ fact k, from mt hp.dvd_fact.1 (not_le_of_gt hkp),
have h₃ : ¬p ∣ fact (p - k), from mt hp.dvd_fact.1 (not_le_of_gt (nat.sub_lt_self hp.pos hk)),
by rw [← choose_mul_fact_mul_fact (le_of_lt hkp), mul_assoc, hp.dvd_mul, hp.dvd_mul] at h₁;
  exact h₁.resolve_right (not_or_distrib.2 ⟨h₂, h₃⟩)

/-- Show that choose is increasing for small values of the right argument. -/
lemma choose_le_succ_of_lt_half_left {r n : ℕ} (h : r < n/2) :
  choose n r ≤ choose n (r+1) :=
begin
  refine le_of_mul_le_mul_right _ (nat.lt_sub_left_of_add_lt (lt_of_lt_of_le h (nat.div_le_self n 2))),
  rw ← choose_succ_right_eq,
  apply nat.mul_le_mul_left,
  rw [← nat.lt_iff_add_one_le, nat.lt_sub_left_iff_add_lt, ← mul_two],
  exact lt_of_lt_of_le (mul_lt_mul_of_pos_right h zero_lt_two) (nat.div_mul_le_self n 2),
end

/-- Show that for small values of the right argument, the middle value is largest. -/
private lemma choose_le_middle_of_le_half_left {n r : ℕ} (hr : r ≤ n/2) :
  choose n r ≤ choose n (n/2) :=
decreasing_induction
  (λ _ k a,
      (eq_or_lt_of_le a).elim
        (λ t, t.symm ▸ le_refl _)
        (λ h, trans (choose_le_succ_of_lt_half_left h) (k h)))
  hr (λ _, le_refl _) hr

/-- `choose n r` is maximised when `r` is `n/2`. -/
lemma choose_le_middle {r n : ℕ} : nat.choose n r ≤ nat.choose n (n/2) :=
begin
  cases le_or_gt r n with b b,
  { cases le_or_lt r (n/2) with a h,
    { apply choose_le_middle_of_le_half_left a },
    { rw ← choose_symm b,
      apply choose_le_middle_of_le_half_left,
      rw [div_lt_iff_lt_mul' zero_lt_two] at h,
      rw [le_div_iff_mul_le' zero_lt_two, nat.mul_sub_right_distrib, nat.sub_le_iff,
          mul_two, nat.add_sub_cancel],
      exact le_of_lt h } },
  { rw nat.choose_eq_zero_of_lt b,
    apply nat.zero_le }
end

section binomial
open finset

variables {α : Type*}

/-- A version of the binomial theorem for noncommutative semirings. -/
theorem commute.add_pow [semiring α] {x y : α} (h : commute x y) (n : ℕ) :
  (x + y) ^ n = ∑ m in range (n + 1), x ^ m * y ^ (n - m) * choose n m :=
begin
  let t : ℕ → ℕ → α := λ n m, x ^ m * (y ^ (n - m)) * (choose n m),
  change (x + y) ^ n = ∑ m in range (n + 1), t n m,
  have h_first : ∀ n, t n 0 = y ^ n :=
    λ n, by { dsimp [t], rw[choose_zero_right, nat.cast_one, mul_one, one_mul] },
  have h_last : ∀ n, t n n.succ = 0 :=
    λ n, by { dsimp [t], rw [choose_succ_self, nat.cast_zero, mul_zero] },
  have h_middle : ∀ (n i : ℕ), (i ∈ finset.range n.succ) →
   ((t n.succ) ∘ nat.succ) i = x * (t n i) + y * (t n i.succ) :=
  begin
    intros n i h_mem,
    have h_le : i ≤ n := nat.le_of_lt_succ (finset.mem_range.mp h_mem),
    dsimp [t],
    rw [choose_succ_succ, nat.cast_add, mul_add],
    congr' 1,
    { rw[pow_succ x, succ_sub_succ, mul_assoc, mul_assoc, mul_assoc] },
    { rw[← mul_assoc y, ← mul_assoc y, (h.symm.pow_right i.succ).eq],
      by_cases h_eq : i = n,
      { rw [h_eq, choose_succ_self, nat.cast_zero, mul_zero, mul_zero] },
      { rw[succ_sub (lt_of_le_of_ne h_le h_eq)],
        rw[pow_succ y, mul_assoc, mul_assoc, mul_assoc, mul_assoc] } }
  end,
  induction n with n ih,
  { rw [_root_.pow_zero, sum_range_succ, range_zero, sum_empty, add_zero],
    dsimp [t], rw [choose_self, nat.cast_one, mul_one, mul_one] },
  { rw[sum_range_succ', h_first],
    rw[finset.sum_congr rfl (h_middle n), finset.sum_add_distrib, add_assoc],
    rw[pow_succ (x + y), ih, add_mul, finset.mul_sum, finset.mul_sum],
    congr' 1,
    rw[finset.sum_range_succ', finset.sum_range_succ, h_first, h_last,
       mul_zero, zero_add, _root_.pow_succ] }
end

/-- The binomial theorem-/
theorem add_pow [comm_semiring α] (x y : α) (n : ℕ) :
  (x + y) ^ n = ∑ m in range (n + 1), x ^ m * y ^ (n - m) * choose n m :=
(commute.all x y).add_pow n

/-- The sum of entries in a row of Pascal's triangle -/
theorem sum_range_choose (n : ℕ) :
  ∑ m in range (n + 1), choose n m = 2 ^ n :=
by simpa using (add_pow 1 1 n).symm

/-!
# Specific facts about binomial coefficients and their sums
-/

private lemma sum_range_reflects_halfway (m : nat) (f : nat → nat)
  (reflects : ∀ x ≤ 2 * m + 1, f x = f (2 * m + 1 - x)) :
  ∑ i in (range (m + 1)), f i = ∑ i in (Ico (m + 1) (2 * m + 2)), f i :=
begin
  have reflect_size : ∀ a (ha : a ∈ range (m + 1)), 2 * m + 1 - a ∈ Ico (m + 1) (2 * m + 2),
    { intros a size,
      rw Ico.mem,
      rw mem_range at size,
      split,
      { apply nat.le_sub_right_of_add_le,
        linarith, },
      { apply (nat.sub_lt_left_iff_lt_add _).2,
        by linarith,
        by linarith, } },
  have reflect_size2 : ∀ a (ha : a ∈ Ico (m + 1) (2 * m + 2)), 2 * m + 1 - a ∈ range (m + 1),
    { intros a size,
      rw Ico.mem at size,
      rw mem_range,
      cases size with a_big a_small,
      apply (nat.sub_lt_left_iff_lt_add _).2,
      by linarith,
      by linarith, },
  have preserves : ∀ a (ha : a ∈ range (m + 1)), f a = f (2 * m + 1 - a),
    { intros a size,
      rw reflects a,
      rw mem_range at size,
      linarith, },

  apply finset.sum_bij' (λ n _, 2 * m + 1 - n) reflect_size preserves (λ n _, 2 * m + 1 - n) reflect_size2,

  { intros a a_in_range,
    simp only [],
    rw nat.sub_sub_self,
    rw mem_range at a_in_range,
    linarith, },
  { intros a a_in_ico,
    rw Ico.mem at a_in_ico,
    simp only [],
    rw nat.sub_sub_self,
    linarith, },
end

lemma sum_range_choose_halfway (m : nat) :
  ∑ i in range (m + 1), nat.choose (2 * m + 1) i = 4 ^ m :=
begin
  have reflects : ∀ x ≤ 2 * m + 1, choose (2 * m + 1) x = choose (2 * m + 1) (2 * m + 1 - x),
  { intros x pr,
    exact eq.symm (@choose_symm (2 * m + 1) x pr), },

  have v : 2 * (∑ i in range (m + 1), nat.choose (2 * m + 1) i) = 2 * 4 ^ m,
    calc 2 * (∑ i in range (m + 1), nat.choose (2 * m + 1) i)
          = ∑ i in range (m + 1), nat.choose (2 * m + 1) i + ∑ i in range (m + 1), nat.choose (2 * m + 1) i : by ring
      ... = ∑ i in range (m + 1), nat.choose (2 * m + 1) i + ∑ i in Ico (m + 1) (2 * m + 2), nat.choose (2 * m + 1) i
              : by rw (sum_range_reflects_halfway m (choose (2 * m + 1)) reflects)
      ... = ∑ i in range (2 * m + 2), nat.choose (2 * m + 1) i
            : by rw @sum_range_add_sum_Ico _ _ (choose (2 * m + 1)) (m + 1) (2 * m + 2) (by linarith)
      ... = 2 ^ (2 * m + 1) : sum_range_choose (2 * m + 1)
      ... = 2 * 2 ^ (2 * m) : by ring_exp
      ... = 2 * 4 ^ m : by { rw nat.pow_mul 2 m 2, refl, },

  exact (@nat.mul_right_inj 2 _ (4 ^ m) (by norm_num)).1 v,
end

end binomial
