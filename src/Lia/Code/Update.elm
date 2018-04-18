module Lia.Code.Update exposing (Msg(..), update)

import Array exposing (Array)
import Lia.Code.Types exposing (EvalString, File, Project, Vector)
import Lia.Helper exposing (ID)
import Lia.Utils


type Msg
    = Eval ID
    | Update ID ID String
    | FlipMode ID ID
    | FlipView ID ID
    | EvalRslt (Result { id : ID, result : String } { id : ID, result : String })
    | Load ID Int


update : Msg -> Vector -> ( Vector, Cmd Msg )
update msg model =
    case msg of
        Eval idx ->
            case Array.get idx model of
                Just project ->
                    ( set_running idx
                        model
                    , project.file
                        |> Array.indexedMap (\i f -> ( i, f.code ))
                        |> Array.foldl replace project.evaluation
                        |> Lia.Utils.evaluateJS2 EvalRslt idx
                    )

                Nothing ->
                    ( model, Cmd.none )

        EvalRslt (Ok { id, result }) ->
            update_ id model (resulting (Ok result)) Cmd.none

        EvalRslt (Err { id, result }) ->
            update_ id model (resulting (Err result)) Cmd.none

        Update id_1 id_2 code_str ->
            update_file id_1 id_2 model (\f -> { f | code = code_str }) Cmd.none

        FlipMode id_1 id_2 ->
            update_file id_1 id_2 model (\f -> { f | editing = not f.editing }) Cmd.none

        FlipView id_1 id_2 ->
            update_file id_1 id_2 model (\f -> { f | visible = not f.visible }) Cmd.none

        Load idx version ->
            update_ idx model (load version) Cmd.none


replace ( int, insert ) into =
    into
        |> String.split ("{{" ++ toString int ++ "}}")
        |> String.join insert


update_ : ID -> Vector -> (Project -> Project) -> Cmd msg -> ( Vector, Cmd msg )
update_ idx model f cmd =
    ( case Array.get idx model of
        Just elem ->
            Array.set idx (f elem) model

        Nothing ->
            model
    , cmd
    )


update_file : ID -> ID -> Vector -> (File -> File) -> Cmd msg -> ( Vector, Cmd msg )
update_file id_1 id_2 model f cmd =
    ( case Array.get id_1 model of
        Just project ->
            case Array.get id_2 project.file of
                Just file ->
                    Array.set id_1 { project | file = Array.set id_2 (f file) project.file } model

                Nothing ->
                    model

        Nothing ->
            model
    , cmd
    )


set_running : ID -> Vector -> Vector
set_running i vector =
    case Array.get i vector of
        Just project ->
            Array.set i
                { project
                    | running = True
                    , file = Array.map (\s -> { s | editing = False }) project.file
                }
                vector

        Nothing ->
            vector


resulting : Result String String -> Project -> Project
resulting result elem =
    let
        ( code, _ ) =
            elem.version
                |> Array.get elem.version_active
                |> Maybe.withDefault ( Array.fromList [], Ok "" )

        e =
            { elem | result = result, running = False }

        new_code =
            e.file |> Array.map .code
    in
    if code == new_code then
        { e
            | version = Array.set e.version_active ( code, result ) e.version
        }
    else
        { e
            | version = Array.push ( new_code, result ) e.version
            , version_active = Array.length e.version
        }


load : Int -> Project -> Project
load version elem =
    if (version >= 0) && (version < Array.length elem.version) then
        let
            ( code, result ) =
                elem.version
                    |> Array.get version
                    |> Maybe.withDefault ( Array.empty, Ok "" )
        in
        { elem
            | version_active = version
            , file = Array.indexedMap (\i a -> { a | code = Array.get i code |> Maybe.withDefault a.code }) elem.file
            , result = result
        }
    else
        elem
