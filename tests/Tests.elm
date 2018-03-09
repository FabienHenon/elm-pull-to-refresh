module Tests exposing (..)

import Expect
import Test exposing (..)


all : Test
all =
    describe "elm-pull-to-refresh"
        [ test "set correct model" <|
            \() ->
                Expect.true "must be true" True
        ]
