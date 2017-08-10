module ParserTests exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import TypeScript.Data.Port
import TypeScript.Data.Program
import TypeScript.Parser


portNameAndDirection : TypeScript.Data.Port.Port -> ( String, TypeScript.Data.Port.Direction )
portNameAndDirection (TypeScript.Data.Port.Port name kind _) =
    ( name, kind )


suite : Test
suite =
    describe "parser"
        [ test "program with no ports" <|
            \_ ->
                """
                  module Main exposing (main)

                  thereAreNoPorts = True
                """
                    |> TypeScript.Parser.parse
                    |> Expect.equal (Ok (TypeScript.Data.Program.ElmProgram Nothing []))
        , test "program with flags" <|
            \_ ->
                """
port module Main exposing (main)

import Html exposing (..)

type Msg
    = NoOp


type alias Model =
    Int


view : Model -> Html Msg
view model =
    div []
        [ text (toString model) ]


init : String -> ( Model, Cmd Msg )
init flags =
    ( 0, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


main : Program String Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = \\_ -> Sub.none
        }
                """
                    |> TypeScript.Parser.parse
                    |> (\parsedProgram ->
                            case parsedProgram of
                                Ok (TypeScript.Data.Program.ElmProgram (Just flagsType) ports) ->
                                    Expect.pass

                                unexpected ->
                                    Expect.fail ("Expected program with flags, got " ++ toString unexpected)
                       )
        , test "program without flags" <|
            \_ ->
                """
port module Main exposing (main)

import Html exposing (..)

type Msg
    = NoOp


type alias Model =
    Int


view : Model -> Html Msg
view model =
    div []
        [ text (toString model) ]


init : ( Model, Cmd Msg )
init flags =
    ( 0, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = \\_ -> Sub.none
        }
                """
                    |> TypeScript.Parser.parse
                    |> (\parsedProgram ->
                            case parsedProgram of
                                Ok (TypeScript.Data.Program.ElmProgram Nothing ports) ->
                                    Expect.pass

                                unexpected ->
                                    Expect.fail ("Expected program without flags, got " ++ toString unexpected)
                       )
        , test "program with an outbound ports" <|
            \_ ->
                """
                  module Main exposing (main)

                  port showSuccessDialog : String -> Cmd msg

                  port showWarningDialog : String -> Cmd msg
                """
                    |> TypeScript.Parser.parse
                    |> (\parsed ->
                            case parsed of
                                Ok (TypeScript.Data.Program.ElmProgram Nothing ports) ->
                                    List.map portNameAndDirection ports
                                        |> Expect.equal
                                            [ ( "showSuccessDialog", TypeScript.Data.Port.Outbound )
                                            , ( "showWarningDialog", TypeScript.Data.Port.Outbound )
                                            ]

                                Err err ->
                                    Expect.fail ("Expected success, got" ++ toString parsed)

                                actual ->
                                    Expect.fail "Expeted program without flags"
                       )
        , test "program with an inbound ports" <|
            \_ ->
                """
                  module Main exposing (main)

                  port localStorageReceived : (String -> msg) -> Sub msg

                  port suggestionsReceived : (String -> msg) -> Sub msg
                """
                    |> TypeScript.Parser.parse
                    |> (\parsed ->
                            case parsed of
                                Ok (TypeScript.Data.Program.ElmProgram Nothing ports) ->
                                    List.map portNameAndDirection ports
                                        |> Expect.equal
                                            [ ( "localStorageReceived", TypeScript.Data.Port.Inbound )
                                            , ( "suggestionsReceived", TypeScript.Data.Port.Inbound )
                                            ]

                                Err err ->
                                    Expect.fail ("Expected success, got" ++ toString parsed)

                                actual ->
                                    Expect.fail "Expeted program without flags"
                       )
        ]
