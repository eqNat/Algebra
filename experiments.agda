{-# OPTIONS --allow-unsolved-metas --cubical --overlapping-instances #-}

open import Prelude
open import Agda.Primitive
open import Relations
open import Algebra.Matrix
open import Algebra.CRing
open import Data.Natural
open import Cubical.Foundations.HLevels
open import Cubical.Foundations.Isomorphism
open import ClassicalTopology.Topology
open import Data.Integer
open import Cubical.HITs.SetQuotients
open import Cubical.HITs.PropositionalTruncation renaming (rec to recTrunc)
open import Data.Finite
open import NumberTheory.Natural
open import Data.Bool

finDecrInj : (f : fin (S n) → fin (S m)) → ((x y : fin (S n)) → f x ≡ f y → x ≡ y) → Σ λ(g : fin n → fin m) → injective g
finDecrInj {n} {m} f fInj = {!!}

JRule : (P : {x y : A} → x ≡ y → Type l) → (x : A) → P (λ _ → x) → {y : A} → (p : x ≡ y) → P p
JRule P x = J (λ y → P {x = x} {y})

JTrans : {a b c : A} → a ≡ b → b ≡ c → a ≡ c
JTrans {A = A} {a = a} {b} {c} p = let P = λ {b c : A} (q : b ≡ c) → a ≡ c
   in JRule P b p 

_==_ : {A : Type l} → A → A → Type (l ⊔ (lsuc lzero))
_==_ {A = A} a b = (P : A → Type) → P a → P b

refl== : {x : A} → x == x
refl== {x = x} = λ P x → x

==K : (P : (x y : A) → Type) → ((x : A) → P x x) → {x y : A} → x == y → P x y
==K P q {x} {y} p = p (P x) (q x)

data circle : Type where
  base : circle
  loop : base ≡ base

flipPath : Bool ≡ Bool
flipPath = isoToPath (iso (λ{ Yes → No ; No → Yes}) (λ{ Yes → No ; No → Yes}) (λ{ Yes → refl ; No → refl}) λ{ Yes → refl ; No → refl})

doubleCover : circle → Type
doubleCover base = Bool
doubleCover (loop i) = flipPath i

endPtOfYes : base ≡ base → doubleCover base
endPtOfYes p = transport (λ i → doubleCover (p i)) Yes

retYes : doubleCover base
retYes = transport (λ i → doubleCover base) Yes

retYes' : doubleCover base
retYes' = transport (λ i → Bool) Yes

retNo : doubleCover base
retNo = transport (λ i → doubleCover (loop i)) Yes

retNo' : doubleCover base
retNo' = transport (λ i → flipPath i) Yes

reflLoopF : ((λ i → base) ≡ loop) → Yes ≡ No
reflLoopF contra = λ i → endPtOfYes (contra i)
pasteCopy : (b r : ℕ) → paste (copy b r) b ≡ Z
pasteCopy b r = {!!}

cutCopy : (b r : ℕ) → cut (copy b r) b ≡ r
cutCopy b r = let H = cutLemma r (copy b r) in
  (cut (copy b r) b ≡⟨ {!!} ⟩
  copy (copy b r) (cut r (copy b r)) ≡⟨ {!!} ⟩
  copy (copy b r) (cut r (copy b r)) + paste r (copy b r) ∎) ∙ sym H

cutUniq : (a b r : ℕ) → copy b r ≡ a → r ≡ cut a b
cutUniq a b r p = {!!}

dividesDec : (a b : ℕ) → Dec (a ∣ b)
dividesDec Z Z = yes ∣ Z , refl ∣₁
dividesDec Z (S b) = no (λ x → recTrunc (λ x → x ~> UNREACHABLE)
    (λ(x , p) → ZNotS (sym (multZ x) ∙ p)) x)
dividesDec (S a) b = let H = cutLemma b a in
       natDiscrete (paste b a) Z
 ~> λ{ (yes p) → yes $ ∣_∣₁ $ cut b a
   , (cut b a * S a ≡⟨ comm (cut b a) (S a)⟩
      copy a (cut b a) ≡⟨ sym (rIdentity (copy a (cut b a)))⟩
      copy a (cut b a) + Z ≡⟨ right _+_ (sym p) ⟩
      (copy a (cut b a)) + paste b a ≡⟨ sym H ⟩
      b ∎)
     ; (no p) → no λ q →
        recTrunc (λ()) (λ(r , q) →
         NEqZ p ~> λ(x , x') →
         q ∙ H ~> λ H →
           let F =  r * S a ≡⟨ H ⟩
                   copy a (cut b a) + paste b a ≡⟨ {!!} ⟩
                   copy a (cut b a) + S x ≡⟨ left _+_ (comm (S a) (cut b a))⟩
                   (cut b a * S a) + S x ≡⟨ {!!} ⟩
                   (r * S a) + S x ∎ in {!!}
          ) q}
                                                                                                               
GCD : (a b : ℕ) → greatest (commonDivisor a (S b))
GCD a b = findGreatest (commonDivisor a (S b))
     (λ n → dividesDec n a
          ~> λ{ (yes p) → dividesDec n (S b)
                     ~> λ{(yes q) → yes (p , q)
                         ; (no q) → no (λ(_ , y) → q y)}
              ; (no p) → no (λ(x , _) → p x)}) ((S Z) , (∣ a , (rIdentity a) ∣₁
                         , ∣ S b , cong S (rIdentity b) ∣₁)) (S b)
                           λ m (x , y) → divides.le m b y