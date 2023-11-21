{-# OPTIONS --cubical --overlapping-instances #-}

-------------------------------------
-- THIS FILE IS A WORK IN PROGRESS --
-------------------------------------
{-
 Every postulate in this file was proven using a different vector definition
 before I switched to Cubical Agda. The new vector definition is more general
  I would like this file to use the '--safe'
 option in the future with all postulates proven.
-}

module Algebra.Matrix where

open import Algebra.Base
open import Algebra.Monoid
open import Algebra.Rng
open import Algebra.Linear
open import Algebra.Module
open import Algebra.Field
open import Data.Base
open import Relations
open import Data.Natural
open import Cubical.Foundations.HLevels
open import Cubical.Foundations.Isomorphism
open import Data.Finite

variable
  dl : Level
  D : Type dl

zip : (A → B → C) → {D : Type l} → (D → A) → (D → B) → (D → C)
zip f u v x = f (u x) (v x)

Matrix : Type l → ℕ → ℕ → Type l
Matrix A n m = [ [ A ^ n ] ^ m ]

instance
  fvect : Functor λ(A : Type l) → B → A
  fvect = record { map = λ f v x → f (v x)
                 ; compPreserve = λ f g → funExt λ x → refl
                 ; idPreserve = funExt λ x → refl }
  mvect : {B : Type l} → Monad λ(A : Type l) → B → A
  mvect = record { μ = λ f a → f a a
                 ; η = λ x _ → x }

zeroV : {{Rng A}} → B → A
zeroV x = 0r

addv : {{R : Rng A}} → (B → A) → (B → A) → (B → A)
addv = zip _+_

negv : {{Rng A}} → (B → A) → (B → A)
negv v x = neg (v x)

multv : {{R : Rng A}} → (B → A) → (B → A) → (B → A)
multv = zip _*_

scaleV : {{Rng A}} → A → (B → A) → (B → A)
scaleV a v x = a * (v x)

foldr : (A → B → B) → B → {n : ℕ} → (fin n → A) → B
foldr f b {Z} _ = b
foldr f b {S n} v = f (head v) (foldr f b (tail v))

foldr∞ : ℕ → (A → B → B) → B → ((a : ℕ) → A) → B
foldr∞ Z f b [] = b
foldr∞ (S n) f b v = f (v n) (foldr∞ n f b v)

dot : {{R : Rng A}} → [ A ^ n ] → [ A ^ n ] → A
dot u v = foldr _+_ 0r (zip _*_ u v)

-- Matrix Transformation
MT : {{R : Rng A}} → (fin n → B → A) → [ A ^ n ] → (B → A)
MT M v x =  dot v (λ y → M y x) 

MT∞ : {{R : Rng A}} → ℕ → (ℕ → B → A) → (ℕ → A) → (B → A)
MT∞ n M v x = foldr∞ n _+_ 0r (zip _*_ v λ y → M y x)

columnSpace : {A : Type l} → {B : Type l'} → {{F : Field A}} → (fin n → B → A) → (B → A) → Type (l ⊔ l')
columnSpace {n = n} M x = ∃ λ y → MT M y ≡ x

rowSpace : {A : Type l} → {B : Type l'} → {{F : Field A}} → (B → fin n → A) → (B → A) → Type (l ⊔ l')
rowSpace {n = n} M = columnSpace {n = n} (transpose M)

mMult∞ : {{R : Rng A}} → ℕ → (ℕ → B → A) → (C → ℕ → A) → C → B → A
mMult∞ n M N c = MT∞ n M (N c)

scalar-distributivity : ∀ {{R : Rng A}} (x y : A) (v : B → A)
                      → scaleV (x + y) v ≡ addv (scaleV x v) (scaleV y v)
scalar-distributivity x y v = funExt λ z → rDistribute (v z) x y

scalar-distributivity2 : ∀ {{R : Rng A}} (s : A) (x y : B → A)
                       → scaleV s (addv x y) ≡ addv (scaleV s x) (scaleV s y)
scalar-distributivity2 s x y = funExt λ z → lDistribute s (x z) (y z)

instance
 comv : {{R : Rng A}} → Commutative (addv {B = B})
 comv {{R}} = record { comm = λ u v → funExt λ x → comm (u x) (v x) }
 assocv : {{R : Rng A}} → Associative (addv {B = B})
 assocv = record { assoc = λ u v w → funExt λ x → assoc (u x) (v x) (w x) }
 grpV : {{R : Ring A}} → group (addv {B = B})
 grpV {{R}} = record { inverse = λ v → map neg v , funExt λ x → lInverse (v x)
                             ; IsSet = isSet→ (monoid.IsSet (Ring.multStr R))
                             ; lIdentity = λ v → funExt (λ x → lIdentity (v x)) }
 abelianV : {{R : Ring A}} → abelianGroup (addv {B = B})
 abelianV = record {}
 vectMod : {A : Type l}{B : Type l'} → {{R : Ring A}} → Module (B → A)
 vectMod {A = A} {B = B} {{R = R}} = record
            { _[+]_ = addv
            ; addvStr = abelianV
            ; scale = scaleV
            ; scalarDistribute = scalar-distributivity2
            ; vectorDistribute = λ v a b → scalar-distributivity a b v
            ; scalarAssoc = λ v c d → funExt λ x → assoc c d (v x)
            ; scaleId = λ v → funExt λ x → lIdentity (v x)
            }

 vectVS : {A : Type l}{B : Type l'} → {{F : Field A}} → VectorSpace {scalar = A} (B → A)
 vectVS = vectMod

foldrMC : {_∙_ : A → A → A}{{M : monoid _∙_}}{{C : Commutative _∙_}} → (u v : [ A ^ n ])
     → foldr _∙_ e (zip _∙_ u v) ≡ foldr _∙_ e u ∙ foldr _∙_ e  v
foldrMC {n = Z} u v = sym(lIdentity e)
foldrMC {n = S n} {_∙_ = _∙_} u v =
      eqTrans (right _∙_ (foldrMC {n = n} (tail u) (tail v))) ([ab][cd]≡[ac][bd] (head u)
                   (head v) (foldr _∙_ e (tail u)) (foldr _∙_ e (tail v)))

instance
-- Matrix transformation over a ring is a module homomorphism.
  MHMT : {{R : Ring A}} → {M : fin n → B → A} → moduleHomomorphism (MT M)
  MHMT {{R}} {M = M} =
   record {
     addT = λ u v → funExt λ x →
     MT M (addv u v) x
       ≡⟨⟩
     foldr _+_ 0r (zip _*_ (addv u v) (transpose M x))
       ≡⟨⟩
     foldr _+_ 0r (λ y → (addv u v) y * transpose M x y)
       ≡⟨⟩
     foldr _+_ 0r (λ y → (u y + v y) * transpose M x y)
       ≡⟨ cong (foldr _+_ 0r ) (funExt λ z → rDistribute (transpose M x z) (u z) (v z))⟩
     foldr _+_ 0r (λ y → ((u y * transpose M x y) + (v y * transpose M x y)))
       ≡⟨⟩
     foldr _+_ 0r  (addv (multv u (transpose M x)) (multv v (transpose M x)))
       ≡⟨ foldrMC (multv u (transpose M x)) (multv v (transpose M x))⟩
     foldr _+_ 0r (multv u (transpose M x)) + foldr _+_ 0r  (multv v (transpose M x))
       ≡⟨⟩
     foldr _+_ 0r (zip _*_ u (transpose M x)) + foldr _+_ 0r  (zip _*_ v (transpose M x))
       ≡⟨⟩
     addv (MT M u) (MT M v) x ∎
   ; multT = λ u c → funExt λ x →
       MT M (scaleV c u) x ≡⟨⟩
       foldr _+_ 0r  (λ y → (c * u y) * M y x) ≡⟨ cong (foldr _+_ 0r ) (funExt λ y → sym (assoc c (u y) (M y x))) ⟩
       foldr _+_ 0r  (λ y → c * (u y * M y x)) ≡⟨ Rec M u c x ⟩
       c * (foldr _+_ 0r  (λ y → u y * M y x)) ≡⟨⟩
       scaleV c (MT M u) x ∎
   }
      where
        Rec : {{R : Ring A}} {n : ℕ} (M : fin n → B → A) (u : fin n → A) → (c : A) → (x : B)
            → foldr _+_ 0r  (λ y → (c * (u y * M y x))) ≡ c * foldr _+_ 0r  (λ y → u y * M y x)
        Rec {n = Z} M u c x = sym (x*0≡0 c)
        Rec {n = S n} M u c x =
          head (λ y → (c * (u y * M y x))) + foldr _+_ 0r  (tail (λ y → (c * (u y * M y x))))
           ≡⟨ right _+_ (Rec {n = n} (tail M) (tail u) c x) ⟩
          (c * head (λ y → u y * M y x)) + (c * (foldr _+_ 0r  (tail(λ y → u y * M y x))))
            ≡⟨ sym (lDistribute c ((head (λ y → u y * M y x))) (foldr _+_ 0r  (tail(λ y → u y * M y x)))) ⟩
          c * (head (λ y → u y * M y x) + foldr _+_ 0r  (tail(λ y → u y * M y x))) ∎
  -- Matrix transformation over a field is a linear map.
  LTMT : {{F : Field A}} → {M : fin n → B → A} → LinearMap (MT M)
  LTMT {{F}} {M = M} = MHMT 

-- Matrix Multiplication
mMult : {{R : Rng A}} → (fin n → B → A) → (C → fin n → A) → C → B → A
mMult  M N c = MT M (N c)

dotDistribute : {{R : Ring A}} → ∀ n → (w u v : [ A ^ n ])
              → dot (u [+] v) w ≡ dot u w + dot v w
dotDistribute Z w u v = sym (lIdentity 0r)
dotDistribute (S n) w u v =
  let v∙w = dot (tail v) (tail w) in
  let u∙w = dot (tail u) (tail w) in
 dot (u [+] v) w ≡⟨⟩
 (head(u [+] v) * head w) + dot (tail(u [+] v)) (tail w) ≡⟨⟩
 ((head u + head v) * head w) + dot ((tail u [+] tail v)) (tail w)
    ≡⟨ right _+_ (dotDistribute n (tail w) (tail u) (tail v))⟩
 ((head u + head v) * head w) + (u∙w + v∙w) ≡⟨ left _+_ (rDistribute (head w)(head u)(head v))⟩
 ((head u * head w) + (head v * head w)) + (u∙w + v∙w)
    ≡⟨ [ab][cd]≡[ac][bd] (head u * head w) (head v * head w) (u∙w) (v∙w)⟩
 ((head u * head w) + u∙w) + ((head v * head w) + v∙w) ≡⟨⟩
 dot u w + dot v w ∎

dotScale : {{R : Ring A}} → (c : A) → (u v : [ A ^ n ])
         → dot (scale c u) v ≡ c * dot u v
dotScale {n = Z} c u v = sym (x*0≡0 c)
dotScale {n = S n} c u v =
 dot (scale c u) v ≡⟨⟩
 (head(scale c u) * head v) + dot (tail(scale c u)) (tail v)
 ≡⟨ right _+_ (dotScale {n = n} c (tail u) (tail v))⟩
 (head(scale c u) * head v) + (c * dot (tail u) (tail v)) ≡⟨⟩
 ((c * head u) * head v) + (c * dot (tail u) (tail v))
 ≡⟨ left _+_ (sym (assoc c (head u) (head v)))⟩
 (c * (head u * head v)) + (c * dot (tail u) (tail v))
 ≡⟨ sym (lDistribute c (head u * head v) (dot (tail u) (tail v)))⟩
 c * ((head u * head v) + dot (tail u) (tail v)) ≡⟨⟩
 c * dot u v ∎

dotZ : {{R : Ring A}}
       → (V : fin n → A)
       → dot (λ _ → 0r) V ≡ 0r
dotZ {n = Z} V = refl
dotZ {n = S n} V =
 (0r * head V) + dot ((λ (_ : fin n) → 0r)) (tail V) ≡⟨ left _+_ (0*x≡0 (head V))⟩
 0r + dot ((λ (_ : fin n) → 0r)) (tail V) ≡⟨ lIdentity (dot ((λ (_ : fin n) → 0r)) (tail V))⟩
 dot ((λ (_ : fin n) → 0r)) (tail V) ≡⟨ dotZ (tail V)⟩
 0r ∎

dotMatrix : {{R : Ring A}}
           → ∀ n m
           → (u : fin n → A)
           → (M : Matrix A n m)
           → (v : fin m → A)
           → dot (λ y → dot v (λ x → M x y)) u ≡ dot v (λ x → dot (M x) u)
dotMatrix n Z u M v = dotZ u
dotMatrix n (S m) u M v =
 dot (λ n' → dot v (λ m' → M m' n')) u ≡⟨⟩
 dot (λ n' → (head v * (head M) n') + dot (tail v) (tail λ m' → M m' n')) u ≡⟨⟩
 dot ((λ n' → (head v * (head M) n')) [+] (λ n' → dot (tail v) (λ m' → (tail M) m' n'))) u
 ≡⟨ dotDistribute n u (λ n' → (head v * head λ m' → M m' n')) (λ n' → dot (tail v) (λ m' → (tail M) m' n'))⟩
 dot (scale (head v) (head M)) u + dot (λ n' → dot (tail v) (λ m' → (tail M) m' n')) u
 ≡⟨ cong₂ _+_ (dotScale {n = n} (head v) (head M) u) (dotMatrix n m u (tail M) (tail v))⟩
 (head v * dot (head M) u) + dot (tail v) (tail λ m' → dot (M m') u) ≡⟨⟩
 dot v (λ m' → dot (M m') u) ∎

dotComm : {{R : CRing A}}
        → ∀ n
        → (u v : [ A ^ n ])
        → dot u v ≡ dot v u
dotComm Z u v = refl
dotComm (S n) u v = cong₂ _+_ (comm (head u) (head v)) (dotComm n (tail u) (tail v))

mMultAssoc : {{R : Ring A}}
           → (M : fin n → B → A)
           → (N : Matrix A n m)
           → (O : C → fin m → A)
           → mMult  M (mMult  N O) ≡ mMult  (mMult  M N) O
mMultAssoc {n = n}{m = m} M N O = funExt λ c → funExt λ b → dotMatrix n m (λ m' → M m' b) N (O c)

transposeMMult : {{R : CRing A}}
               → (M : fin n → C → A)
               → (N : B → fin n → A)
               → transpose (mMult  M N) ≡ mMult  (transpose N) (transpose M)
transposeMMult {A = A} {n = n} {C = C} {B = B} M N = funExt λ c → funExt λ b →
    transpose (mMult  M N) c b ≡⟨⟩
    dot (N b) (λ x → M x c) ≡⟨ dotComm n (N b) (λ x → M x c)⟩
    dot (λ x → M x c) (N b) ≡⟨⟩
    mMult  (transpose N) (transpose M) c b ∎

indicateEqRing : {{R : Ring A}} → (n : ℕ) → {a b : fin n} → Dec (a ≡ b) → A
indicateEqRing n (yes p) = 1r
indicateEqRing n (no ¬p) = 0r

-- infinite identity matrix
I∞ : {{R : Ring A}} → ℕ → ℕ → A
I∞ Z Z = 1r
I∞ Z (S b) = 0r
I∞ (S a) Z = 0r
I∞ (S a) (S b) = I∞ a b

I∞Transpose : {{R : Ring A}} → I∞ ≡ transpose I∞
I∞Transpose = funExt λ x → funExt λ y → Rec x y
  where
  Rec : {A : Type l} {{R : Ring A}} → (x y : ℕ) → I∞ {{R}} x y ≡ I∞ y x
  Rec Z Z = refl
  Rec Z (S y) = refl
  Rec (S x) Z = refl
  Rec (S x) (S y) = Rec x y

-- Identity Matrix
--I : {{R : Ring A}} (n : ℕ) → Matrix A n n
--I n x y = I∞ (pr1 x) (pr1 y)

DecEqP : (x y : A) → Dec(x ≡ y) ≡ Dec(y ≡ x)
DecEqP x y = isoToPath (iso (λ{ (yes p) → yes (sym p) ; (no p) → no (λ z → p (sym z))}) ( λ{ (yes p) → yes (sym p) ; (no p) → no (λ z → p (sym z))}) (λ{ (yes z) → refl ; (no z) → refl}) λ{ (yes x) → refl ; (no x) → refl})

--idTranspose : {{R : Ring A}} (n : ℕ) → I n ≡ transpose (I n)
--idTranspose n = funExt λ{(x , _) → funExt λ{(y , _) → funRed (funRed I∞Transpose x) y}}
--
--postulate
-- IRID : {{R : Ring A}} (M : fin n → B → A) → mMult  M (I n) ≡ M
-- ILID : {{R : Ring A}} (M : B → fin n → A) → mMult  (I n) M ≡ M
-- sqrMMultAssoc : {{R : Ring A}}
--            → (M : fin n → B → A)
--            → (N : Matrix A n n)
--            → (O : C → fin n → A)
--            → mMult  M (mMult  N O) ≡ mMult  (mMult  M N) O
-- IMT : {A : Type l} {{R : Ring A}} → (v : [ A ^ n ]) → MT (I n) v ≡ v
-- sqrMMultMonoid : {{R : Ring A}} → monoid (mMult  {B = fin n} {C = fin n})
