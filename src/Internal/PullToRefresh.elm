module Internal.PullToRefresh exposing (..)

import Json.Decode as JD
import Html exposing (Html)
import Time exposing (Time)
import Ease exposing (Easing)


type State
    = None
    | Start Position
    | Moving Position Position
    | Loading Float Time
    | Ending Float Time


type alias Model =
    { currScrollY : Float
    , state : State
    , loading : Bool
    , startLoading : Time
    }


type alias Config msg =
    { id : String
    , maxDist : Float
    , triggerDist : Float
    , pullContent : Html msg
    , releaseContent : Html msg
    , loadingContent : Html msg
    , animationEasingFunc : Easing
    , animationDuration : Time
    , refreshCmd : Cmd msg
    , manualScroll : Bool
    , minLoadingDuration : Time
    }


initModel : Config msg -> Model
initModel config =
    { currScrollY = 0.0
    , state = None
    , loading = False
    , startLoading = 0
    }



-- Logic


isStarted : State -> Bool
isStarted state =
    case state of
        Start position ->
            True

        Moving _ _ ->
            True

        None ->
            False

        Loading _ _ ->
            True

        Ending _ _ ->
            False


start : Position -> State -> State
start position state =
    case state of
        None ->
            Start position

        Start initial ->
            state

        Moving initial _ ->
            state

        Loading _ _ ->
            state

        Ending _ _ ->
            state


move : Position -> State -> State
move position state =
    case state of
        None ->
            state

        Start initial ->
            Moving initial position

        Moving initial _ ->
            Moving initial position

        Loading _ _ ->
            state

        Ending _ _ ->
            state


end : Float -> Position -> State -> State
end maxDist position state =
    case state of
        None ->
            state

        Start initial ->
            Loading (yPos maxDist initial position) 0

        Moving initial _ ->
            Loading (yPos maxDist initial position) 0

        Loading _ _ ->
            state

        Ending _ _ ->
            state


reset : Float -> Float -> State -> State
reset triggerDist maxDist state =
    case state of
        None ->
            state

        Start initial ->
            None

        Moving initial position ->
            Ending (yPos maxDist initial position) 0

        Loading _ _ ->
            Ending triggerDist 0

        Ending _ _ ->
            state


updateAnim : Time -> Time -> State -> State
updateAnim animationDuration diff state =
    case state of
        None ->
            state

        Start _ ->
            state

        Moving _ _ ->
            state

        Loading topPos elapsedTime ->
            Loading topPos (elapsedTime + diff)

        Ending topPos elapsedTime ->
            if (elapsedTime + diff) >= animationDuration then
                None
            else
                Ending topPos (elapsedTime + diff)


yPos : Float -> Position -> Position -> Float
yPos maxDist start curr =
    if start.y < curr.y then
        resistanceFunction maxDist (curr.y - start.y)
    else
        0


getContentTopPosition : Config msg -> State -> Float
getContentTopPosition { maxDist, triggerDist, animationDuration, animationEasingFunc } state =
    case state of
        None ->
            0

        Start position ->
            0

        Moving initial curr ->
            yPos maxDist initial curr

        Loading maxTop elapsedTime ->
            triggerDist + (maxTop - triggerDist) * (animationEasingFunc ((max (animationDuration - elapsedTime) 0) / animationDuration))

        Ending maxTop elapsedTime ->
            maxTop * (animationEasingFunc ((max (animationDuration - elapsedTime) 0) / animationDuration))


resistanceFunction : Float -> Float -> Float
resistanceFunction maxDist x =
    (1.0 - (1.0 / (1.0 + (x / maxDist)))) * maxDist



-- Decoders


decodeScrollPos : JD.Decoder Float
decodeScrollPos =
    JD.at [ "target", "scrollTop" ] JD.float


type alias Position =
    { x : Float, y : Float }


decodeMousePosition : JD.Decoder Position
decodeMousePosition =
    JD.map2 Position
        (JD.field "clientX" JD.float)
        (JD.field "clientY" JD.float)
