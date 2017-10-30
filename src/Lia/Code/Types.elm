module Lia.Code.Types exposing (Code(..), CodeElement, Codes)

import Array exposing (Array)
import Dict exposing (Dict)


type alias Codes =
    Dict String CodeElement


type alias CodeElement =
    { code : String
    , history : Array String
    , result : Result String String
    , editing : Bool
    , running : Bool
    }


type Code
    = Highlight String String -- Lang Code
    | Evaluate String String (List String) -- Lang ID EvalString
