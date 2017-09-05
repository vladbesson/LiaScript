module Lia.Effect.Parser exposing (eblock, ecomment, einline)

--import Lia.Effect.Types exposing (Comment)

import Combine exposing (..)
import Combine.Num exposing (int)
import Lia.Inline.Types exposing (Inline(..))
import Lia.PState exposing (PState)
import Lia.Types exposing (Block(..))


eblock : Parser PState Block -> Parser PState Block
eblock blocks =
    let
        name =
            maybe (regex "[a-zA-Z ]+")

        multi_block =
            regex "( *){{[\\n]+" *> manyTill (blocks <* regex "[ \\n\\t]*") (regex "( *)}}")

        single_block =
            List.singleton <$> (regex "[ \\n\\t]*" *> blocks)
    in
    EBlock
        <$> (regex "( *){{" *> effect_number)
        <*> (regex "( *)" *> name <* regex "}}( *)[\\n]")
        <*> (multi_block <|> single_block)


einline : Parser PState Inline -> Parser PState Inline
einline inlines =
    let
        name =
            maybe (regex "[a-zA-Z ]+")

        multi_inline =
            string "{{" *> manyTill inlines (string "}}")
    in
    EInline
        <$> (string "{{" *> effect_number)
        <*> (regex "( *)" *> name <* string "}}")
        <*> multi_inline


effect_number : Parser PState Int
effect_number =
    let
        state n =
            modifyState
                (\s ->
                    if n > s.num_effects then
                        { s | num_effects = n }
                    else
                        s
                )
                *> succeed n
    in
    int >>= state


ecomment : Parser PState (List Inline) -> Parser PState Block
ecomment paragraph =
    let
        number =
            regex "( *)--{{" *> effect_number <* regex "}}--( *)[\\n]+"
    in
    EComment <$> number <*> paragraph
