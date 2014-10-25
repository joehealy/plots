{-# LANGUAGE CPP                    #-}
{-# LANGUAGE DefaultSignatures      #-}
{-# LANGUAGE DeriveDataTypeable     #-}
{-# LANGUAGE FlexibleContexts       #-}
{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE ImpredicativeTypes     #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE MultiWayIf             #-}
{-# LANGUAGE ScopedTypeVariables    #-}
{-# LANGUAGE TemplateHaskell        #-}
{-# LANGUAGE TupleSections          #-}
{-# LANGUAGE TypeFamilies           #-}
{-# LANGUAGE TypeOperators          #-}
{-# LANGUAGE UndecidableInstances   #-}

module Plots.Axis where

import Control.Lens       hiding (lmap, transform, ( # ))
import Data.Default
import Data.Typeable
import Diagrams.Prelude   as D hiding (under, view)
import Diagrams.TwoD.Text

-- import Diagrams.Core.Transform

import Data.Monoid.Recommend

import Plots.Axis.Grid
import Plots.Axis.Labels
import Plots.Axis.Ticks
import Plots.Legend
import Plots.Themes
import Plots.Types

import Diagrams.Projections

-- Lines types

-- | Where axis line for coordinate should be drawn.
data AxisLineType
  = BoxAxisLine
  | LeftAxisLine
  | MiddleAxisLine
  | RightAxisLine
  | NoAxisLine
  deriving (Show, Eq, Typeable)

instance Default AxisLineType where
  def = BoxAxisLine

-- | Information about position and style of axis lines.
data AxisLine n = AxisLine
  { _axisLineType  :: AxisLineType
  , _axisArrowOpts :: Maybe (ArrowOpts n)
  } deriving Typeable

makeLenses ''AxisLine

type AxisLines v n = v (AxisLine n)

instance Default (AxisLine n) where
  def = AxisLine
          { _axisLineType  = def
          , _axisArrowOpts = def
          }

-- Scaling

type AspectRatio v n = v n

data ScaleMode = AutoScale
               | NoScale
               | Stretch
               | UniformScale UniformScaleStrategy
  deriving (Show, Read)

data UniformScaleStrategy = AutoUniformScale
                          | UnitOnly
                          | ChangeVerticalLimits
                          | ChangeHorizontalLimits
  deriving (Show, Read)

data Scaling n = Scaling
  { _aspectRatio        :: Recommend n
  , _axisPostScale      :: Maybe n
  , _axisScaleMode      :: ScaleMode
  , _enlargeAxisLimits  :: Maybe (Recommend n)
  }
  deriving Show


makeLenses ''Scaling

type AxisScaling v n = v (Scaling n)

instance Fractional n => Default (Scaling n) where
  def = Scaling
          { _aspectRatio       = Recommend 1
          , _axisPostScale     = Nothing
          , _axisScaleMode     = AutoScale
          , _enlargeAxisLimits = Just $ Recommend 0.1
          }

-- axis data type

-- | Axis is the data type that holds all the nessessary information to render
--   a plot. The idea is to use one of the default axis, customise, add plots
--   and render using @drawAxis@.
data Axis b v n = Axis
  
  { -- These lenses are not being exported, they're just here for instances.
    _axisAxisBounds :: Bounds v n

  -- These lenses are exported.
  , _axisGridLines  :: AxisGridLines v n
  , _axisLabels     :: AxisLabels b v n
  , _axisLegend     :: Legend b n
  , _axisLinearMap  :: v n -> V2 n
  , _axisLines      :: AxisLines v n
  , _axisPlots      :: [Plot b v n]
  , _axisScaling    :: AxisScaling v n
  , _axisSize       :: SizeSpec V2 n
  , _axisTheme      :: Theme b n
  , _axisTickLabels :: AxisTickLabels b v n
  , _axisTicks      :: AxisTicks v n
  , _axisTitle      :: Maybe String
  } deriving Typeable

makeLenses ''Axis

type instance V (Axis b v n) = v
type instance N (Axis b v n) = n

axisLine :: E v -> Lens' (Axis b v n) (AxisLine n)
axisLine (E l) = axisLines . l

instance HasBounds (Axis b v n) where
  bounds = axisAxisBounds

-- R2 axis

instance (TypeableFloat n, Enum n, Renderable (Text n) b, Renderable (Path V2 n) b) => Default (Axis b V2 n) where
  def = Axis
          { _axisTitle      = Nothing
          , _axisSize       = mkWidth 300
          , _axisPlots      = []
          , _axisLegend     = def
          , _axisTheme      = coolTheme
          , _axisLinearMap  = id
          , _axisAxisBounds = Bounds $ pure def
          , _axisGridLines  = pure def
          , _axisLabels     = pure def
          , _axisScaling    = pure def
          , _axisTickLabels = pure def
          , _axisTicks      = pure def
          , _axisLines      = pure def
          }

-- R3 Axis

instance (TypeableFloat n, Enum n, Renderable (Text n) b, Renderable (Path V2 n) b) => Default (Axis b V3 n) where
  def = Axis
          { _axisTitle      = Nothing
          , _axisSize       = mkWidth 300
          , _axisPlots      = []
          , _axisLegend     = def
          , _axisTheme      = coolTheme
          , _axisLinearMap  = isometricProjection
          , _axisAxisBounds = Bounds $ pure def
          , _axisGridLines  = pure def
          , _axisLabels     = pure def
          , _axisScaling    = pure def
          , _axisTickLabels = pure def
          , _axisTicks      = pure def
          , _axisLines      = pure def
          }

-- Drawing the axis

getAxisLinePos :: (Num n, Ord n) => (n, n) -> AxisLineType -> [n]
getAxisLinePos (a,b) aType = case aType of
  BoxAxisLine    -> [a, b]
  LeftAxisLine   -> [a]
  MiddleAxisLine -> [if | a > 0     -> a
                        | b < 0     -> b
                        | otherwise -> 0]
  RightAxisLine  -> [b]
  NoAxisLine     -> []

