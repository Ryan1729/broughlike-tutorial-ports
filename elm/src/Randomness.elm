module Randomness exposing (probability, shuffle, shuffleNonEmpty, tryTo)

import Random exposing (Generator)


probability : Generator Float
probability =
    Random.float 0 1


shuffle : List a -> Generator (List a)
shuffle list =
    shuffleHelper list 0


shuffleHelper : List a -> Int -> Generator (List a)
shuffleHelper list i =
    Random.int 0 i
        |> Random.andThen
            (\randomIndex ->
                let
                    newList =
                        swapAt i randomIndex list

                    newI =
                        i + 1
                in
                if newI < List.length newList then
                    shuffleHelper newList newI

                else
                    Random.constant newList
            )


swapAt : Int -> Int -> List a -> List a
swapAt i j list =
    if i == j || i < 0 then
        list

    else if i > j then
        swapAt j i list

    else
        let
            beforeI =
                List.take i list

            iAndAfter =
                List.drop i list

            jInIAndAfter =
                j - i

            iToBeforeJ =
                List.take jInIAndAfter iAndAfter

            jAndAfter =
                List.drop jInIAndAfter iAndAfter
        in
        case ( iToBeforeJ, jAndAfter ) of
            ( valueAtI :: afterIToJ, valueAtJ :: rest ) ->
                List.concat [ beforeI, valueAtJ :: afterIToJ, valueAtI :: rest ]

            _ ->
                list


shuffleNonEmpty : ( a, List a ) -> Generator ( a, List a )
shuffleNonEmpty list =
    shuffleNonEmptyHelper list 0


shuffleNonEmptyHelper : ( a, List a ) -> Int -> Generator ( a, List a )
shuffleNonEmptyHelper list i =
    Random.int 0 i
        |> Random.andThen
            (\randomIndex ->
                let
                    newList =
                        swapAtNonEmpty i randomIndex list

                    newI =
                        i + 1
                in
                if newI < lengthNonEmpty newList then
                    shuffleNonEmptyHelper newList newI

                else
                    Random.constant newList
            )


lengthNonEmpty : ( a, List a ) -> Int
lengthNonEmpty ( _, rest ) =
    1 + List.length rest


swapAtNonEmpty : Int -> Int -> ( a, List a ) -> ( a, List a )
swapAtNonEmpty i j list =
    if i == j || i < 0 then
        list

    else if i > j then
        swapAtNonEmpty j i list

    else
        let
            ( head, rest ) =
                list
        in
        if i == 0 then
            let
                beforeJ =
                    List.take (j + 1) rest

                jAndAfter =
                    List.drop (j + 1) rest
            in
            case jAndAfter of
                valueAtJ :: restOfRest ->
                    ( valueAtJ, List.concat [ beforeJ, head :: restOfRest ] )

                _ ->
                    list

        else
            ( head
            , swapAt (i + 1) (j + 1) rest
            )


tryTo : Generator (Result String a) -> Generator (Result String a)
tryTo generator =
    tryToHelper generator 1000


tryToHelper : Generator (Result String a) -> Int -> Generator (Result String a)
tryToHelper generator timeout =
    Random.andThen
        (\result ->
            case result of
                Ok a ->
                    Ok a
                        |> Random.constant

                Err description ->
                    if timeout <= 0 then
                        "Timeout while trying to "
                            ++ description
                            |> Err
                            |> Random.constant

                    else
                        tryToHelper generator (timeout - 1)
        )
        generator
