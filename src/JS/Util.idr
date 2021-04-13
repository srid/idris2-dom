||| Javascript utilities. If these prove to be useful in
||| applications, they should eventually go into their
||| own package.
module JS.Util

import Control.Monad.Either
import Data.Maybe

export
doubleToBool : Double -> Bool
doubleToBool d = d /= 0.0

%foreign "javascript:lambda:v=>typeof(v)"
prim__typeOf : AnyPtr -> String

||| Inspect the type of a value at runtime by means of
||| Javascript function `typeof`.
export
typeof : a -> String
typeof v = prim__typeOf (believe_me v)

%foreign "javascript:lambda:(a,b)=>a === b?1:0"
prim__eqv : AnyPtr -> AnyPtr -> Double

||| Heterogeneous pointer equality. This calls the Javascript
||| `===` operator internally.
export
eqv : a -> b -> Bool
eqv x y = doubleToBool $ prim__eqv (believe_me x) (believe_me y)

%foreign "javascript:lambda:x=>String(x)"
prim__show : AnyPtr -> String

||| Displays a JS value by passing it to `String(...)`.
export
jsShow : a -> String
jsShow v = prim__show (believe_me v)

--------------------------------------------------------------------------------
--          IO
--------------------------------------------------------------------------------

%foreign "browser:lambda:x=>console.log(x)"
prim__consoleLog : String -> PrimIO ()

export
consoleLog : String -> IO ()
consoleLog s = fromPrim $ prim__consoleLog s

public export
data JSErr : Type where
  CastErr   : (inFunction : String) -> (value : a) -> JSErr
  IsNothing : (callSite : String) -> JSErr

dispErr : JSErr -> String
dispErr (CastErr inFunction value) = #"""
  Error when casting a Javascript value in function \#{inFunction}.
    The value was: \#{jsShow value}.
    The value's type was \#{typeof value}.
  """#

dispErr (IsNothing callSite) =
  #"Trying to extract a value from Nothing at \#{callSite}"#


public export
JSIO : Type -> Type
JSIO = EitherT JSErr IO

export
runJSWith : Lazy (JSErr -> IO a) -> JSIO a -> IO a
runJSWith f (MkEitherT io) = io >>= either f pure

export
runJS : JSIO () -> IO ()
runJS = runJSWith (consoleLog . dispErr)

export
runJSWithDefault : Lazy a -> JSIO a -> IO a
runJSWithDefault a = runJSWith (\e => consoleLog (dispErr e) $> a)

export %inline
primJS : PrimIO a -> JSIO a
primJS = primIO

export
unMaybe : (callSite : String) -> JSIO (Maybe a) -> JSIO a
unMaybe callSite io = do Just a <- io
                           | Nothing => throwError $ IsNothing callSite
                         pure a

--------------------------------------------------------------------------------
--          Common external types
--------------------------------------------------------------------------------

||| See [spec](https://html.spec.whatwg.org/#windowproxy)
export
data WindowProxy : Type where [external]

--------------------------------------------------------------------------------
--          Aliases
--------------------------------------------------------------------------------

||| A String alias used in some CSS functions.
public export
0 CSSOMString : Type
CSSOMString = String
