module WithSmallContent exposing (main)

import Html exposing (Html, div, p, text)
import Html.Attributes exposing (style)
import Process
import PullToRefresh as PR
import Task
import Time exposing (second)


type Msg
    = PullToRefreshMsg PR.Msg
    | Finished ()


type alias Model =
    { pullToRefresh : PR.Model
    }


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


initModel : PR.Model -> Model
initModel pullToRefresh =
    { pullToRefresh = pullToRefresh
    }


pullToRefreshConfig : PR.Config Msg
pullToRefreshConfig =
    PR.config "content-id"
        |> PR.withRefreshCmd (Process.sleep (5 * second) |> Task.perform Finished)


init : ( Model, Cmd Msg )
init =
    let
        ( pullToRefresh, cmd ) =
            PR.init pullToRefreshConfig
    in
    ( initModel pullToRefresh, Cmd.map PullToRefreshMsg cmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PullToRefreshMsg msg_ ->
            let
                ( pullToRefresh, cmd ) =
                    PR.update PullToRefreshMsg msg_ pullToRefreshConfig model.pullToRefresh
            in
            ( { model | pullToRefresh = pullToRefresh }, cmd )

        Finished () ->
            ( model, PR.stopLoading PullToRefreshMsg )


view : Model -> Html Msg
view model =
    div
        [ style "border" "1px solid #000"
        , style "margin" "auto"
        , style "height" "500px"
        , style "width" "300px"
        , style "position" "relative"
        ]
        [ PR.view PullToRefreshMsg
            pullToRefreshConfig
            model.pullToRefresh
            []
            [ div
                []
                [ content ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    PR.subscriptions PullToRefreshMsg pullToRefreshConfig model.pullToRefresh


content : Html Msg
content =
    div []
        [ p []
            [ text """
                Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
                Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute
                irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
                cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
                """
            ]
        ]
