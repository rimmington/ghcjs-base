{-# LANGUAGE ForeignFunctionInterface, JavaScriptFFI, UnliftedFFITypes,
             GHCForeignImportPrim, DeriveDataTypeable, GHCForeignImportPrim #-}
module GHCJS.Foreign.Callback
    ( Callback
    , OnBlocked(..)
    , releaseCallback
    , asyncCallback
    , asyncCallback1
    , asyncCallback2
    , asyncCallback3
    , syncCallback
    , syncCallback1
    , syncCallback2
    , syncCallback3
    ) where

import           GHCJS.Concurrent
import           GHCJS.Marshal
import           GHCJS.Marshal.Pure
import           GHCJS.Foreign.Callback.Internal
import           GHCJS.Prim
import           GHCJS.Types

import qualified GHC.Exts as Exts

import           Data.Typeable

import           Unsafe.Coerce

{- |
     When you create a callback, the Haskell runtime stores a reference to
     the exported IO action or function. This means that all data referenced by the
     exported value stays in memory, even if nothing outside the Haskell runtime
     holds a reference to to callback.

     Use 'releaseCallback' to free the reference. Subsequent calls from JavaScript
     to the callback will result in an exception.
 -}
releaseCallback :: Callback a -> IO ()
releaseCallback x = js_release x

{- | Make a callback (JavaScript function) that runs the supplied IO action in a synchronous
     thread when called.

     Call 'releaseCallback' when done with the callback, freeing memory referenced
     by the IO action.
 -}
syncCallback :: OnBlocked                               -- ^ what to do when the thread blocks
             -> IO ()                                   -- ^ the Haskell action
             -> IO (Callback (IO ()))                   -- ^ the callback
syncCallback onBlocked x = js_syncCallback (onBlocked == ContinueAsync) (unsafeCoerce x)


{- | Make a callback (JavaScript function) that runs the supplied IO function in a synchronous
     thread when called. The callback takes one argument that it passes as a JSVal value to
     the Haskell function.

     Call 'releaseCallback' when done with the callback, freeing data referenced
     by the function.
 -}
syncCallback1 :: OnBlocked                             -- ^ what to do when the thread blocks
              -> (JSVal -> IO ())                      -- ^ the Haskell function
              -> IO (Callback (JSVal -> IO ()))        -- ^ the callback
syncCallback1 onBlocked x = js_syncCallbackApply (onBlocked == ContinueAsync) 1 (unsafeCoerce x)


{- | Make a callback (JavaScript function) that runs the supplied IO function in a synchronous
     thread when called. The callback takes two arguments that it passes as JSVal values to
     the Haskell function.

     Call 'releaseCallback' when done with the callback, freeing data referenced
     by the function.
 -}
syncCallback2 :: OnBlocked                               -- ^ what to do when the thread blocks
              -> (JSVal -> JSVal -> IO ())               -- ^ the Haskell function
              -> IO (Callback (JSVal -> JSVal -> IO ())) -- ^ the callback
syncCallback2 onBlocked x = js_syncCallbackApply (onBlocked == ContinueAsync) 2 (unsafeCoerce x)

{- | Make a callback (JavaScript function) that runs the supplied IO function in a synchronous
     thread when called. The callback takes three arguments that it passes as JSVal values to
     the Haskell function.

     Call 'releaseCallback' when done with the callback, freeing data referenced
     by the function.
 -}
syncCallback3 :: OnBlocked                               -- ^ what to do when the thread blocks
              -> (JSVal -> JSVal -> JSVal -> IO ())               -- ^ the Haskell function
              -> IO (Callback (JSVal -> JSVal -> JSVal -> IO ())) -- ^ the callback
syncCallback3 onBlocked x = js_syncCallbackApply (onBlocked == ContinueAsync) 3 (unsafeCoerce x)



{- | Make a callback (JavaScript function) that runs the supplied IO action in an asynchronous
     thread when called.

     Call 'releaseCallback' when done with the callback, freeing data referenced
     by the IO action.
 -}
asyncCallback :: IO ()              -- ^ the action that the callback runs
              -> IO (Callback (IO ())) -- ^ the callback
asyncCallback x = js_asyncCallback (unsafeCoerce x)

asyncCallback1 :: (JSVal -> IO ())            -- ^ the function that the callback calls
               -> IO (Callback (JSVal -> IO ())) -- ^ the calback
asyncCallback1 x = js_asyncCallbackApply 1 (unsafeCoerce x)

asyncCallback2 :: (JSVal -> JSVal -> IO ())            -- ^ the Haskell function that the callback calls
               -> IO (Callback (JSVal -> JSVal -> IO ())) -- ^ the callback
asyncCallback2 x = js_asyncCallbackApply 2 (unsafeCoerce x)

asyncCallback3 :: (JSVal -> JSVal -> JSVal -> IO ())               -- ^ the Haskell function that the callback calls
               -> IO (Callback (JSVal -> JSVal -> JSVal -> IO ())) -- ^ the callback
asyncCallback3 x = js_asyncCallbackApply 3 (unsafeCoerce x)

-- ----------------------------------------------------------------------------

foreign import javascript unsafe "h$makeCallback(h$runSync, [$1], $2)"
  js_syncCallback :: Bool -> Exts.Any -> IO (Callback (IO b))
foreign import javascript unsafe "h$makeCallback(h$run, [], $1)"
  js_asyncCallback :: Exts.Any -> IO (Callback (IO b))

foreign import javascript unsafe "h$makeCallbackApply($2, h$runSync, [$1], $3)"
  js_syncCallbackApply :: Bool -> Int -> Exts.Any -> IO (Callback b)
foreign import javascript unsafe "h$makeCallbackApply($1, h$run, [], $2)"
  js_asyncCallbackApply :: Int -> Exts.Any -> IO (Callback b)

foreign import javascript unsafe "h$release"
  js_release :: Callback a -> IO ()

