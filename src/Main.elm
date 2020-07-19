port module Main exposing (Model, Msg(..), ensureTrailingNewline, init, main, update, view)

-- import Html exposing (Html, button, div, h1, header, span, text, textarea)
-- import Html.Attributes exposing (class, cols, rows, value)
-- import Html.Events exposing (onClick, onInput)

import Browser
import Element exposing (Element, column, el, fill, fillPortion, height, html, rgb255, row, scrollbarY, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html.Parser
import Html.Parser.Util exposing (toVirtualDom)
import Http exposing (Error(..))
import List as L
import Parser exposing (deadEndsToString)
import String exposing (endsWith, trim)



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
    trim s ++ "\n"



-- ---------------------------
-- VIEW
-- ---------------------------


view model =
    Element.layout [height fill, width fill] <|
        column [ height <| fillPortion 1, width fill ]
            [ Element.el
                [ Font.size 42
                ]
                (Element.text "Screenplay Editor")
            , row [ height <| fillPortion 10, width fill ]
                [ editPanel model
                , viewPanel model
                ]
            ]


editPanel : Model -> Element Msg
editPanel model =
    column [ height fill, width <| fillPortion 1 ]
        [ column
            [ Background.color <| rgb255 92 99 118
            , scrollbarY
            ]
            [ Input.multiline []
                { onChange = ChangeScreenplay
                , text = model.rawScreenplay
                , placeholder = Nothing
                , label = Input.labelHidden "Raw-text screenplay input, in fountain markup"
                , spellcheck = False
                }
            ]
        ]


viewPanel : Model -> Element Msg
viewPanel model =
    column [ height fill, width <| fillPortion 1 ]
        [ column
            [ width <| fillPortion 1
            , scrollbarY
            , Background.color <| rgb255 92 99 118
            ]
            [ column [ Background.color <| rgb255 255 255 255 ] (valueFor model.renderedScreenplay) ]
        ]


valueFor : String -> List (Element Msg)
valueFor renderedScreenplay =
    case Html.Parser.run renderedScreenplay of
        Ok htmlScreenplay ->
            toVirtualDom htmlScreenplay |> L.map html

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
