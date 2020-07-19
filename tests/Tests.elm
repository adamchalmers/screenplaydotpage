module Tests exposing (unitTest)

import Expect exposing (Expectation)
import Main exposing (..)
import Test exposing (..)


{-| See <https://github.com/elm-community/elm-test>
-}
unitTest : Test
unitTest =
    describe "ensureTrailingNewline"
        [ test "string ends with newline" <|
            \() ->
                ensureTrailingNewline "adam\n"
                    |> Expect.equal "adam\n"
        , test "string without newline" <|
            \() ->
                ensureTrailingNewline "adam"
                    |> Expect.equal "adam\n"
        , test "string with too many newlines" <|
            \() ->
                ensureTrailingNewline "adam\n\n\n"
                    |> Expect.equal "adam\n"
        ]
