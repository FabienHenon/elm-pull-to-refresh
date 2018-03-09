module InfiniteScrollContent exposing (main)

import InfiniteScroll as IS
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (style)
import Html.Events as Events
import Http
import Json.Decode as JD
import PullToRefresh as PR


type Msg
    = InfiniteScrollMsg IS.Msg
    | OnDataRetrieved (Result Http.Error (List String))
    | PullToRefreshMsg PR.Msg
    | OnScroll JD.Value


type alias Model =
    { infScroll : IS.Model Msg
    , content : List String
    , pullToRefresh : PR.Model
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
    { infScroll = IS.init loadMore |> IS.offset 0 |> IS.direction IS.Bottom
    , content = []
    , pullToRefresh = pullToRefresh
    }


pullToRefreshConfig : PR.Config Msg
pullToRefreshConfig =
    PR.config "content-id"
        |> PR.withRefreshCmd Cmd.none
        |> PR.withManualScroll True


init : ( Model, Cmd Msg )
init =
    let
        model =
            initModel pullToRefresh

        ( pullToRefresh, cmd ) =
            PR.init pullToRefreshConfig
    in
        ( { model | infScroll = IS.startLoading model.infScroll }, Cmd.batch [ Cmd.map PullToRefreshMsg cmd, loadContent ] )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InfiniteScrollMsg msg_ ->
            let
                ( infScroll, cmd ) =
                    IS.update InfiniteScrollMsg msg_ model.infScroll
            in
                ( { model | infScroll = infScroll }, cmd )

        PullToRefreshMsg msg_ ->
            let
                ( pullToRefresh, cmd ) =
                    PR.update PullToRefreshMsg msg_ pullToRefreshConfig model.pullToRefresh
            in
                ( { model | pullToRefresh = pullToRefresh }, cmd )

        OnDataRetrieved (Err _) ->
            let
                infScroll =
                    IS.stopLoading model.infScroll
            in
                ( { model | infScroll = infScroll }, Cmd.none )

        OnDataRetrieved (Ok result) ->
            let
                content =
                    List.concat [ model.content, result ]

                infScroll =
                    IS.stopLoading model.infScroll
            in
                ( { model | content = content, infScroll = infScroll }, Cmd.none )

        OnScroll value ->
            ( model
            , Cmd.batch
                [ PR.cmdFromScrollEvent PullToRefreshMsg value
                , IS.cmdFromScrollEvent InfiniteScrollMsg value
                ]
            )


stringsDecoder : JD.Decoder (List String)
stringsDecoder =
    JD.list JD.string


loadContent : Cmd Msg
loadContent =
    Http.get "https://baconipsum.com/api/?type=all-meat&paras=10" stringsDecoder
        |> Http.send OnDataRetrieved


loadMore : IS.Direction -> Cmd Msg
loadMore dir =
    loadContent


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "border", "1px solid #000" )
            , ( "margin", "auto" )
            , ( "height", "500px" )
            , ( "width", "300px" )
            , ( "position", "relative" )
            ]
        ]
        [ PR.view PullToRefreshMsg
            pullToRefreshConfig
            model.pullToRefresh
            [ style
                [ ( "border", "1px solid #000" )
                , ( "margin", "auto" )
                ]
            , Events.on "scroll" (JD.map OnScroll JD.value)
            ]
            ((List.map viewContentItem model.content) ++ loader model)
        ]


viewContentItem : String -> Html Msg
viewContentItem item =
    p [] [ text item ]


loader : Model -> List (Html Msg)
loader { infScroll } =
    if IS.isLoading infScroll then
        [ div
            [ style
                [ ( "color", "red" )
                , ( "font-weight", "bold" )
                , ( "text-align", "center" )
                ]
            ]
            [ text "Loading ..." ]
        ]
    else
        []


subscriptions : Model -> Sub Msg
subscriptions model =
    PR.subscriptions PullToRefreshMsg pullToRefreshConfig model.pullToRefresh
