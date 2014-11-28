{-# LANGUAGE DeriveDataTypeable    #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE UndecidableInstances  #-}
{-# LANGUAGE ConstraintKinds       #-}

module Plots.Types.Line where
  -- ( LinePlot
  --   -- * Constucting Line Plots
  -- , mkLinePlotFromVerticies
  -- , mkLinePlotFromPath
  -- , mkMultiLinePlotFromVerticies

  --   -- * Prism
  -- , _LinePlot

  --   -- * Lenses
  -- , linePlotPath
  -- ) where

import Control.Lens     hiding (transform, ( # ), lmap)
import Data.Foldable    as F
import Data.Typeable
import Diagrams.Prelude
import Diagrams.LinearMap
-- import Diagrams.ThreeD.Types

import Diagrams.Coordinates.Isomorphic

import Plots.Themes
import Plots.Types

mkTrail :: (PointLike v n p, OrderedField n, Foldable f) => f p -> Located (Trail v n)
mkTrail = mkTrailOf folded

mkTrailOf :: (PointLike v n p, OrderedField n) => Fold s p -> s -> Located (Trail v n)
mkTrailOf f ps = fromVertices $ toListOf (f . unpointLike) ps

mkPathOf :: (PointLike v n p, OrderedField n) => Fold s t -> Fold t p -> s -> Path v n
mkPathOf f1 f2 as = Path $ map (mkTrailOf f2) (toListOf f1 as)

mkPath :: (PointLike v n p, OrderedField n, Foldable f, Foldable g) => g (f p) -> Path v n
mkPath = mkPathOf folded folded

instance (Typeable v, TypeableFloat n, HasLinearMap v, Metric v, Renderable (Path V2 n) b)
    => Plotable (Path v n) b where
  renderPlotable info _ tv l t2 path
    = stroke (path # transform tv # lmap l # transform t2)
        # applyStyle (info ^. themeLineStyle)

  defLegendPic info _
    = (p2 (-10,0) ~~ p2 (10,0))
        # applyStyle (info ^. themeLineStyle)



------------------------------------------------------------------------
-- Sample
------------------------------------------------------------------------

-- kernalDensity :: Int -> Fold s n -> s -> LinePlot V2 n
-- kernalDensity n f as = 


