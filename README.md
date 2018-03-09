# elm-pull-to-refresh [![Build Status](https://travis-ci.org/FabienHenon/elm-pull-to-refresh.svg?branch=master)](https://travis-ci.org/FabienHenon/elm-pull-to-refresh)

```
elm package install FabienHenon/elm-pull-to-refresh
```

Pull to refresh allows you to pull the top of your page to refresh your content.
This is working with touches and mouse.

## Getting started

### Types
First you need to add pull to refresh to your messages and your model.

```elm
import PullToRefresh

type Msg
    = PullToRefreshMsg PullToRefresh.Msg

type alias Model =
    { pullToRefresh : PullToRefresh.Model
    , content : List String
    }
```

### Configuration
Sets the configuration of the pull to refresh module

```elm
pullToRefreshConfig : PullToRefresh.Config Msg
pullToRefreshConfig =
    PullToRefresh.config "your-content-div-id"
        |> PullToRefresh.withRefreshCmd onLoad
```

### Initialization
Initializes your model.

```elm
init : ( Model, Cmd Msg )
init =
    let
        ( pullToRefresh, cmd ) =
            PullToRefresh.init pullToRefreshConfig
    in
        ( { pullToRefresh = pullToRefresh, content = initialContent }, Cmd.map PullToRefreshMsg cmd )
```

### View
Then, you need to add your pull to refresh component to your `view`.

```elm
view : Model -> Html Msg
view model =
    PullToRefresh.view PullToRefreshMsg
        pullToRefreshConfig
        model.pullToRefresh
        []
        [ div []
            (List.map text model.content)
        ]
```

This will create an absolute element using the full space of its parent. Inside it, your content and attributes will be added in another element with touch and scroll handling. If you need to handle scroll manually see `withManualScroll` function.

### Refresh cmd
You have to define a function that will be called when we need to refresh page content. This function must return a `Cmd Msg`.

Here is an example with data retrieved from a remote API:

```elm
type Msg
    -- ... add this message
    | OnDataRetrieved (Result Http.Error String)

onLoad : Cmd Msg
onLoad =
    Http.getString "https://example.com/retrieve-more"
        |> Http.send OnDataRetrieved
```

### Update
Finally, all we need to do is to implement the update function.

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PullToRefreshMsg msg_ ->
            let
                ( pullToRefresh, cmd ) =
                    PullToRefresh.update PullToRefreshMsg msg_ pullToRefreshConfig model.pullToRefresh
            in
                ( { model | pullToRefresh = pullToRefresh }, cmd )

        OnDataRetrieved (Err _) ->
            -- Don't forget to handle error
            ( model, PullToRefresh.stopLoading PullToRefreshMsg )

        OnDataRetrieved (Ok result) ->
            let
                content =
                    addContent result model.content
            in
                ( { model | content = content }, PullToRefresh.stopLoading PullToRefreshMsg )
```

In the update you have to handle pull to refresh update. It will return an updated model and a command to execute.

You also have to handle your data refreshing, and **don't forget to call `stopLoading`** so that loading animation finishes and the user is able to pull the view again.

## Examples

To run the examples go to the `examples` directory, install dependencies and run `elm-reactor`:

```
> cd examples/
> elm package install
> elm-reactor
```
