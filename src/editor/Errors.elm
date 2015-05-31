module Errors where

import Html exposing (..)
import Html.Attributes exposing (..)
import String


-- MAIN

main =
  view sourceCode errors


port sourceCode : String

port errors : List Error


-- MODEL

type alias Error =
  { region : Region
  , subregion : Maybe Region
  , tag : String
  , overview : String
  , details : String
  }


type alias Region =
  { start : Position
  , end : Position
  }


type alias Position =
  { line : Int
  , column : Int
  }


-- VIEW

(=>) = (,)


view : String -> List Error -> Html
view sourceCode errors =
  div [] (List.map (viewError sourceCode) errors)


viewError : String -> Error -> Html
viewError sourceCode error =
  div []
    [ h2 [] [text error.tag]
    , pre [] [text error.overview]
    , code [] (grabRegion sourceCode error.region error.subregion)
    , pre [] [text error.details]
    ]


-- GRAB REGION

grabRegion : String -> Region -> Maybe Region -> List Html
grabRegion sourceCode region maybeSubregion =
  let
    formatLine ((number, line) as lineInfo) =
      div [] <|
      case grabSubregion maybeSubregion lineInfo of
        Nothing ->
            [text line]

        Just (start, end) ->
            [ text (String.left start line)
            , span
                [style ["color" => "red"]]
                [text (String.slice start end line)]
            , text (String.dropLeft end line)
            ]

    lines =
      String.split "\n" sourceCode

    numberedLines =
      List.map2 (,) [1.. List.length lines] lines
        |> List.filter (\(n,_) -> region.start.line <= n && n <= region.end.line)
        |> List.map formatLine
  in
    numberedLines


-- SUBREGIONS

grabSubregion : Maybe Region -> (Int, String) -> Maybe (Int,Int)
grabSubregion maybeSubregion lineInfo =
  maybeSubregion
    `Maybe.andThen` \subregion -> startColumn subregion lineInfo
    `Maybe.andThen` \start -> endColumn subregion lineInfo
    `Maybe.andThen` \end -> Just (start, end)


startColumn : Region -> (Int, String) -> Maybe Int
startColumn region (number, _) =
  if region.start.line == number then
    Just (region.start.column - 1)

  else if region.start.line < number then
    Just 0

  else
    Nothing


endColumn : Region -> (Int, String) -> Maybe Int
endColumn region (number, line) =
  if region.end.line == number then
    Just region.end.column

  else if number < region.end.line then
    Just (String.length line)

  else
    Nothing
