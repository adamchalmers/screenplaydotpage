port module Main exposing (Model, Msg(..), ensureTrailingNewline, init, main, update, view)

-- import Html exposing (Html, button, div, h1, header, span, text, textarea)
-- import Html.Attributes exposing (class, cols, rows, value)
-- import Html.Events exposing (onClick, onInput)

import Browser
import Element exposing (Element, alignBottom, alignRight, column, el, fill, fillPortion, height, html, layout, mouseOver, none, padding, paddingXY, paragraph, rgb255, row, scrollbarY, scrollbars, spacingXY, text, width, wrappedRow)
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
    layout [ height fill ] <|
        column [ height fill, width fill ]
            [ row
                [ Background.color <| rgb255 30 30 30
                , Font.color <| rgb255 200 200 200
                , width fill
                , Font.size 52
                , padding 10
                ]
                [ text "Write a screenplay" ]
            , row [ scrollbars ]
                [ writePanel model
                , readPanel model
                ]
            ]


writePanel : Model -> Element Msg
writePanel model =
    let
        editor =
            [ Input.multiline []
                { onChange = ChangeScreenplay
                , text = model.rawScreenplay
                , placeholder = Nothing
                , label = Input.labelHidden "Raw-text screenplay input, in fountain markup"
                , spellcheck = False
                }
            ]
    in
    column
        [ height fill
        , width fill
        , paddingXY 0 10
        , scrollbars
        , Background.color <| rgb255 92 99 118
        ]
    <|
        editor


readPanel : Model -> Element Msg
readPanel model =
    let

        -- Wrap the lines so that they can't be wider than the read panel itself.
        renderedElements =
            L.map (\line -> paragraph [] [ line ]) <|
                valueFor model.renderedScreenplay
    in
    column
        [ height fill
        , width fill
        ]
        [ column
            [ padding 10
            , spacingXY 0 20
            , scrollbarY
            , Font.family [ Font.monospace ]
            ]
            renderedElements
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
