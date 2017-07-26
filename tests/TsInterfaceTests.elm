module TsInterfaceTests exposing (..)

import Electron.Generator.Ts
import Electron.Ipc
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "ts"
        [ test "interface for msg with no parameters" <|
            \() ->
                Electron.Ipc.Msg "HideWindow"
                    |> Electron.Generator.Ts.generateInterface
                    |> Expect.equal
                        "interface HideWindow {\n  message: 'HideWindow'\n}"
        , test "union" <|
            \() ->
                [ Electron.Ipc.Msg "HideWindow" ]
                    |> Electron.Generator.Ts.generateUnion
                    |> Expect.equal
                        "type ElmIpc =\n | ShowFeedbackForm"
        ]
