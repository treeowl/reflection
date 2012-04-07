{-# LANGUAGE TypeFamilies, Rank2Types, GADTs #-}
----------------------------------------------------------------------------
-- |
-- Module     : Data.Reflection
-- Copyright  : 2009-2012 Edward Kmett,
--              2012 Elliott Hird,
--              2004 Oleg Kiselyov and Chung-chieh Shan
-- License    : BSD3
--
-- Maintainer  : Edward Kmett <ekmett@gmail.com>
-- Stability   : experimental
-- Portability : non-portable (rank-2 types, type families, scoped type variables)
--
-- Based on the Functional Pearl: Implicit Configurations paper by
-- Oleg Kiselyov and Chung-chieh Shan.
--
-- <http://www.cs.rutgers.edu/~ccshan/prepose/prepose.pdf>
--
-- The approach from the paper was modified to work with Data.Proxy
-- and to cheat by using knowledge of GHC's internal representations
-- by Edward Kmett and Elliott Hird.
--
-- Usage reduces to using two combinators, 'reify' and 'reflect'.
--
-- > ghci> reify 6 (\p -> reflect p + reflect p) :: Int
-- > 12
--
-- The argument passed along by reify is just a @data Proxy t =
-- Proxy@, so all of the information needed to reconstruct your value
-- has been moved to the type level.  This enables it to be used when
-- constructing instances (see @examples/Monoid.hs@).
-------------------------------------------------------------------------------
module Data.Reflection
    (
    -- * Reifying any term at the type level
      Reified(..)
    , reify
    ) where

import Data.Proxy
import Unsafe.Coerce

class Reified s where
  type Reflected s
  reflect :: p s -> Reflected s

data Equal a b where Refl :: Equal a a

newtype Magic a w = Magic (forall s. Reified s => Equal (Reflected s) a -> Proxy s -> w)

reify' :: a -> (forall s. Reified s => Equal (Reflected s) a -> Proxy s -> w) -> w
reify' a k = (unsafeCoerce (Magic k) $! const a) (unsafeCoerce Refl) Proxy

reify :: a -> (forall s. (Reified s, Reflected s ~ a) => Proxy s -> w) -> w
reify a k = reify' a $ \Refl p -> k p