port module Main exposing (Model, Msg(..), ensureTrailingNewline, init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, header, span, text, textarea)
import Html.Attributes exposing (class, cols, rows, value)
import Html.Events exposing (onClick, onInput)
import Html.Parser
import Html.Parser.Util exposing (toVirtualDom)
import Http exposing (Error(..))
import Parser exposing (deadEndsToString)
import String exposing (endsWith)



-- ---------------------------
-- PORTS
-- ---------------------------


port renderRequest : String -> Cmd msg


port renderResponse : (String -> msg) -> Sub msg



-- ---------------------------
-- MODEL
-- ---------------------------


type alias Model =
    { serverMessage : String
    , rawScreenplay : String
    , render : String
    , renderedScreenplay : String
    }

type alias Flags =
    { startingText : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { serverMessage = ""
      , rawScreenplay = flags.startingText
      , render = ""
      , renderedScreenplay = ""
      }
    , makeRenderRequest flags.startingText
    )




-- ---------------------------
-- UPDATE
-- ---------------------------


type Msg
    = ChangeScreenplay String
    | Render
    | RenderComplete String


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        ChangeScreenplay raw ->
            ( { model | rawScreenplay = raw }, makeRenderRequest raw )

        Render ->
            ( model, makeRenderRequest model.rawScreenplay )

        RenderComplete render ->
            ( { model | renderedScreenplay = render }, Cmd.none )


makeRenderRequest : String -> Cmd Msg
makeRenderRequest raw =
    renderRequest (ensureTrailingNewline raw)


ensureTrailingNewline : String -> String
ensureTrailingNewline s =
    if endsWith "\n" s then
        s

    else
        s ++ "\n"



-- ---------------------------
-- VIEW
-- ---------------------------


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ header []
            [ h1 [] [ text "Screenplay editor" ]
            ]
        , div [ class "pure-g" ]
            [ button
                [ class "pure-button pure-button-primary"
                , onClick Render
                ]
                [ text "render" ]
            ]
        , div [ class "pure-u-1-3" ]
            [ textarea [ value model.rawScreenplay, onInput ChangeScreenplay, rows 40, cols 20 ] [] ]
        , div [ class "pure-u-1-3" ] [ div [] (valueFor model.renderedScreenplay) ]
        ]


valueFor : String -> List (Html Msg)
valueFor renderedScreenplay =
    case Html.Parser.run renderedScreenplay of
        Ok html ->
            toVirtualDom html

        Err errs ->
            [ text <| deadEndsToString errs ]



-- ---------------------------
-- SUBSCRIPTIONS
-- ---------------------------
-- Subscribe to the `messageReceiver` port to hear about messages coming in
-- from JS. Check out the index.html file to see how this is hooked up to a
-- WebSocket.
--


subscriptions : Model -> Sub Msg
subscriptions _ =
    renderResponse RenderComplete



-- ---------------------------
-- MAIN
-- ---------------------------


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view =
            \m ->
                { title = "Elm 0.19 starter"
                , body = [ view m ]
                }
        , subscriptions = subscriptions
        }
