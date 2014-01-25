{-# LANGUAGE DeriveDataTypeable         #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE NoMonomorphismRestriction  #-}
{-# LANGUAGE TemplateHaskell            #-}

module Database.Groundhog.Utils where

-------------------------------------------------------------------------------
import           Control.Lens
import           Data.ByteString.Char8      (ByteString)
import           Data.Default
import           Data.SafeCopy
import           Data.Serialize
import           Data.Typeable
import           Database.Groundhog         as GH
import           Database.Groundhog.Core    as GH
import           Database.Groundhog.Generic as GH
import           GHC.Generics
-------------------------------------------------------------------------------


-- | Pull the Int out of a db AutoKey.
getKey :: (SinglePersistField a, PersistBackend m) => a -> m Int
getKey k = toSinglePersistValue k >>= fromSinglePersistValue


-------------------------------------------------------------------------------
mkKey :: (PersistBackend m, SinglePersistField a, SinglePersistField b) => a -> m b
mkKey k = toSinglePersistValue k >>= fromSinglePersistValue


-------------------------------------------------------------------------------
keyToInt
    :: (DbDescriptor db, PrimitivePersistField (Key a b))
    => Proxy db
    -> Key a b
    -> Int
keyToInt p = keyToIntegral p


-------------------------------------------------------------------------------
-- | Convert 'Key' to any integral type.
keyToIntegral
    :: (DbDescriptor db, PrimitivePersistField i, PrimitivePersistField (Key a b))
    => Proxy db
    -> Key a b
    -> i
keyToIntegral proxy =
    fromPrimitivePersistValue proxy . toPrimitivePersistValue proxy


-------------------------------------------------------------------------------
-- | Type specialized input for type inference convenience.
intToKey
    :: (DbDescriptor db, PrimitivePersistField (Key a b))
    => Proxy db
    -> Int
    -> Key a b
intToKey p = integralToKey p


-------------------------------------------------------------------------------
-- | Convert any integral type to 'Key'
integralToKey
    :: (DbDescriptor db, PrimitivePersistField i, PrimitivePersistField (Key a b))
    => Proxy db
    -> i
    -> Key a b
integralToKey proxy =
    fromPrimitivePersistValue proxy . toPrimitivePersistValue proxy


-- | SafeCopy PrimitivePersistField wrapper. Anything you stuff in
-- here will be persisted in database as a SafeCopy blob.
newtype SC a = SC { getSC :: a } deriving (Eq,Show,Read,Ord,Generic,Typeable)
makeIso ''SC
makeWrapped ''SC

instance SafeCopy a => PersistField (SC a) where
    persistName _ = "SC" ++ delim : delim : persistName (undefined :: ByteString)
    toPersistValues = primToPersistValue
    fromPersistValues = primFromPersistValue
    dbType _ = DbTypePrimitive DbBlob False Nothing Nothing

instance SafeCopy a => PrimitivePersistField (SC a) where
    toPrimitivePersistValue p (SC a) = toPrimitivePersistValue p $ runPut $ safePut a
    fromPrimitivePersistValue p x =
      either (error "SafeCopy failed in SC wrapper.") SC $
        runGet safeGet (fromPrimitivePersistValue p x)



-- | Show PrimitivePersistField wrapper.
newtype Sh a = Sh { getShow :: a }
    deriving (Eq,Show,Read,Ord,Generic,Typeable,Default,NeverNull)
makeIso ''Sh
makeWrapped ''Sh

instance (Show a, Read a) => PersistField (Sh a) where
    persistName _ = "Sh" ++ delim : delim : persistName (undefined :: ByteString)
    toPersistValues = primToPersistValue
    fromPersistValues = primFromPersistValue
    dbType _ = DbTypePrimitive DbString False Nothing Nothing

instance (Show a, Read a) => PrimitivePersistField (Sh a) where
    toPrimitivePersistValue p (Sh a) = toPrimitivePersistValue p $ show a
    fromPrimitivePersistValue p x = Sh $ read (fromPrimitivePersistValue p x)