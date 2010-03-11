
#light
namespace Ioke.Lang.Parser.Functional
open System
open System.Collections
open System.Collections.Generic
open Ioke.Lang
open Ioke.Lang.Parser
open Ioke.Lang.Util

type LevelType =
    | Attach
    | Arg
    | New
    | Unused

type Level =
    { mutable message    : IokeObject;
      mutable level      : LevelType;
      mutable precedence : int; }

type FunctionalOperatorShuffler(msg:IokeObject, context:IokeObject, message:IokeObject) =
    let OP_LEVEL_MAX = 32

    let level level = { level = level;
                        precedence = 0;
                        message = null; }
    let attach level msg =
        match level with
            | {level = Attach} -> Message.SetNext(level.message, msg)
            | {level = Arg}    -> Message.AddArg(level.message, msg)
            | {level = New}    -> level.message <- msg
            | {level = Unused} -> ()

    let awaitingFirstArg level msg precedence =
        level.level <- Arg
        level.message <- msg
        level.precedence <- precedence

    let alreadyHasArgs level msg =
        level.level <- Attach
        level.message <- msg

    let (|Detach|Clear|None|) (arg:IokeObject, message:IokeObject) =
        match (message.Name, arg.Name, arg.Arguments.Count, Message.GetNext(arg)) with
            | (_, "", 1, null) -> Detach
            | ("'", _, _, _) -> None
            | (_, ".", _, null) -> Clear
            | _ -> None


    let into_list l = List.ofSeq(Seq.cast l : seq<Object>)
    let add_all (l1 : IList) l2 =
        Seq.iter (fun arg -> l1.Add(arg) |> ignore) (Seq.cast l2 : seq<Object>)

    let finish level (expressions : IList<IokeObject>) =
        match level.message with
            | null -> ()
            | message ->
                Message.SetNext(message, null)

                match into_list message.Arguments with
                    | ( :? IokeObject as arg) :: [] ->
                        match (arg, message) with
                            | Detach ->
                                match SaneArrayList.IndexOf(expressions, arg) with
                                    | -1 -> ()
                                    | index -> expressions.[index] <- message
                                message.Arguments.Clear()
                                add_all message.Arguments arg.Arguments
                            | Clear  -> message.Arguments.Clear()
                            | None   -> ()
                    | _ -> ()
        level.level <- Unused


    let defaultOperators = [
        ("!",   0);
        ("?",   0);
        ("$",   0);
        ("~",   0);
        ("#",   0);

        ("**",  1);

        ("*",   2);
        ("/",   2);
        ("%",   2);

        ("+",   3);
        ("-",   3);
        ("∩",   3);
        ("∪",   3);

        ("<<",  4);
        (">>",  4);

        ("<=>",  5);
        (">",   5);
        ("<",   5);
        ("<=",  5);
        ("≤",  5);
        (">=",  5);
        ("≥",  5);
        ("<>",  5);
        ("<>>",  5);
        ("⊂",  5);
        ("⊃",  5);
        ("⊆",  5);
        ("⊇",  5);

        ("==",  6);
        ("!=",  6);
        ("≠",  6);
        ("===",  6);
        ("=~",  6);
        ("!~",  6);

        ("&",   7);

        ("^",   8);

        ("|",   9);

        ("&&",  10);
        ("?&",  10);

        ("||",  11);
        ("?|",  11);

        ("..",  12);
        ("...",  12);
        ("=>",  12);
        ("<->",  12);
        ("->",  12);
        ("∘", 12);
        ("+>",  12);
        ("!>",  12);
        ("&>",  12);
        ("%>",  12);
        ("#>",  12);
        ("@>",  12);
        ("/>",  12);
        ("*>",  12);
        ("?>",  12);
        ("|>",  12);
        ("^>",  12);
        ("~>",  12);
        ("->>",  12);
        ("+>>",  12);
        ("!>>",  12);
        ("&>>",  12);
        ("%>>",  12);
        ("#>>",  12);
        ("@>>",  12);
        ("/>>",  12);
        ("*>>",  12);
        ("?>>",  12);
        ("|>>",  12);
        ("^>>",  12);
        ("~>>",  12);
        ("=>>",  12);
        ("**>",  12);
        ("**>>",  12);
        ("&&>",  12);
        ("&&>>",  12);
        ("||>",  12);
        ("||>>",  12);
        ("$>",  12);
        ("$>>",  12);

        ("+=",  13);
        ("-=",  13);
        ("**=",  13);
        ("*=",  13);
        ("/=",  13);
        ("%=",  13);
        ("and",  13);
        ("nand",  13);
        ("&=",  13);
        ("&&=",  13);
        ("^=",  13);
        ("or",  13);
        ("xor",  13);
        ("nor",  13);
        ("|=",  13);
        ("||=",  13);
        ("<<=", 13);
        (">>=", 13);

        ("<-",  14);

        ("return", 14);
        ("import", 14)
        ]

    let defaultTrinaryOperators = [
        ("=", 2);
        ("+=", 2);
        ("-=", 2);
        ("/=", 2);
        ("*=", 2);
        ("**=", 2);
        ("%=", 2);
        ("&=", 2);
        ("&&=", 2);
        ("|=", 2);
        ("||=", 2);
        ("^=", 2);
        ("<<=", 2);
        (">>=", 2);
        ("++", 1);
        ("--", 1)
        ]

    let defaultInvertedOperators = [
        ("∈", 12);
        ("∉", 12);
        ("::", 12);
        (":::", 12)
        ]

    let opTableCreator opTable (runtime:Runtime) =
        let table : IDictionary = new SaneHashtable() :> IDictionary
        opTable |> List.iter (fun (name, precedence) -> table.Item(runtime.GetSymbol(name)) <- runtime.NewNumber(precedence : int))
        table

    let runtime = context.runtime

    let opTable =
        match IokeObject.As(msg.FindCell(message, context, "OperatorTable"), null) with
            | x when x = (runtime.nul :> IokeObject) ->
                let x = runtime.NewFromOrigin()
                x.Kind <- "Message OperatorTable"
                runtime.Message.SetCell("OperatorTable", x)
                x.SetCell("precedenceLevelCount", runtime.NewNumber(OP_LEVEL_MAX))
                x
            | opTable -> opTable

    let getOpTable (opTable : IokeObject) name creator =
        let create_new () =
            let result = creator runtime
            opTable.SetCell(name, runtime.NewDict(result))
            result

        match IokeObject.As(opTable.FindCell(message, context, name), null) with
            | x when x = (runtime.nul :> IokeObject) -> create_new ()
            | operators ->
                match IokeObject.dataOf(operators) with
                    | :? Dict -> Dict.GetMap(operators)
                    | _ -> create_new ()

    let operatorTable = getOpTable opTable "operators" (opTableCreator defaultOperators)
    let trinaryOperatorTable = getOpTable opTable "trinaryOperators" (opTableCreator defaultTrinaryOperators)
    let invertedOperatorTable = getOpTable opTable "invertedOperators" (opTableCreator defaultInvertedOperators)

    let mutable stack : Level list = []

    let (pool : Level array) = Array.zeroCreate OP_LEVEL_MAX

    let mutable currentLevel = 0

    let reset () =
        currentLevel <- 1
        for i = 0 to OP_LEVEL_MAX - 1 do
            pool.[i] <- {level = Unused;
                         precedence = 0;
                         message = null;}
        let level = pool.[0]
        level.message <- null
        level.level <- New
        level.precedence <- OP_LEVEL_MAX
        stack <- [pool.[0]]

    do reset ()

    let isInverted ms = invertedOperatorTable.Contains(ms)

    let (|Operator|InvertedOperator|OtherOp|) sym =
        if operatorTable.Contains(sym) then
            Operator(Number.GetValue(operatorTable.[sym]).intValue())
        else
            if invertedOperatorTable.Contains(sym) then
                InvertedOperator(Number.GetValue(invertedOperatorTable.[sym]).intValue())
            else
                OtherOp

    let levelForOp (messageName : string) messageSymbol msg =
        match messageSymbol with
            | Operator(prec) -> prec
            | InvertedOperator(prec) -> prec
            | OtherOp ->
                match messageName.Length with
                    | 0 -> -1
                    | _ ->
                        match messageName.[0] with
                            | '|' -> 9
                            | '^' -> 8
                            | '&' -> 7
                            | '<' -> 5
                            | '>' -> 5
                            | '=' -> 6
                            | '!' -> 6
                            | '?' -> 6
                            | '~' -> 6
                            | '$' -> 6
                            | '+' -> 3
                            | '-' -> 3
                            | '*' -> 2
                            | '/' -> 2
                            | '%' -> 2
                            | _ -> -1


    let argCountForOp messageName messageSymbol msg =
        if trinaryOperatorTable.Contains(messageSymbol) then
            Number.GetValue(trinaryOperatorTable.[messageSymbol]).intValue()
        else
            -1

    let CurrentLevel () = stack.[0]

    let popDownTo targetLevel expressions =
        let rec helper () =
            match stack with
                | []  -> ()
                | level :: rest ->
                    match level.level with
                        | Arg -> ()
                        | _ when level.precedence <= targetLevel ->
                            stack <- rest
                            finish level expressions
                            currentLevel <- currentLevel - 1
                            helper ()
                        | _ -> ()
        helper ()


    let attachAndReplace self msg =
        attach self msg
        self.level <- Attach
        self.message <- msg

    let attachToTopAndPush msg precedence =
        let top = stack.[0]
        attachAndReplace top msg

        let level = pool.[currentLevel]
        currentLevel <- currentLevel + 1
        awaitingFirstArg level msg precedence
        stack <- level :: stack

    let nextMessage expressions =
        stack |> List.iter (fun hd -> finish hd expressions)
        reset ()

    let rec find_direction (transform : IokeObject -> IokeObject) current =
        match transform current with
            | null -> current
            | transformed ->
                if not(Message.IsTerminator(transformed)) then
                    find_direction transform transformed
                else
                    current

    let find_last = find_direction (fun next -> Message.GetNext(next))
    let find_head = find_direction (fun head -> Message.GetPrev(head))

    // : "str" bar   becomes   :("str") bar
    // -foo bar      becomes   -(foo) bar
    let handle_unary_prefix_message (precedence, msgArgCount) (msg : IokeObject) =
        match (msgArgCount, Message.GetNext(msg), Message.GetName(msg), Message.IsFirstOnLine(msg)) with
            | (_, null, _, _) -> (precedence, msgArgCount)
            | (0, _, (":" | "'" | "`" | "''"), _) | (0, _, "-", true) ->
                let arg = Message.GetNext(msg)
                Message.SetNext(msg, Message.GetNext(arg))
                if not(Message.GetNext(arg) = null) then
                   Message.SetPrev(Message.GetNext(arg), msg)
                Message.SetNext(arg, null);
                Message.SetPrev(arg, null);
                msg.Arguments.Add(arg) |> ignore
                (-1, msgArgCount + 1)
            | _ -> (precedence, msgArgCount)


    let rec find_direction_inverted (transform : IokeObject -> IokeObject) current =
        match transform current with
            | null -> current
            | transformed ->
                if not(Message.IsTerminator(transformed)) && 
                   not(isInverted(runtime.GetSymbol(Message.GetName(transformed))) && 
                       0 = transformed.Arguments.Count) then
                    find_direction transform transformed
                else
                    current

    let find_last_inverted = find_direction_inverted (fun next -> Message.GetNext(next))

    let actual_detaching msgArgCount (msg : IokeObject) =
        let head = find_head msg
        if not(Object.ReferenceEquals(head, msg)) then
            Message.SetNext(Message.GetPrev(msg), null)
            Message.SetPrev(msg, null)

            let next = Message.GetNext(msg)
            Message.SetNext(msg, null)
            Message.SetPrev(next, null)

            let last = find_last_inverted next

            let cont = Message.GetNext(last)
            Message.SetNext(last, null)
            if not(cont = null) then
               Message.SetPrev(cont, null)
            
            Message.SetNext(msg, cont)
            if not(cont = null) then
                Message.SetPrev(cont, msg)

            let argPart = Message.DeepCopy(head)
            msg.Arguments.Add(argPart) |> ignore
            (-1, msgArgCount + 1) |> ignore
            
            Message.SetNext(last, msg)
            Message.SetPrev(msg, last)

            head.Become(next, null, null)

            // be sure to update the prev reference to the head object
            Message.SetPrev(Message.GetNext(head), head)

            // attaching inverted op to the last message
            let currentLevel = CurrentLevel ()
            currentLevel.message <- last
            
        msgArgCount

    let handle_detach_of_message (precedence, msgArgCount) inverted (msg : IokeObject) =
        match (inverted, msgArgCount) with
            | (true, 0) ->
                (precedence, actual_detaching msgArgCount msg)
            | _ -> (precedence, msgArgCount)


    // o a = b c . d  becomes  o =(a, b c) . d
    //
    // a      attaching
    // =      msg
    // b c    Message.next(msg)
    let restructure_assignment_operation msgArgCount (msg : IokeObject) messageName (expressions : IList<IokeObject>) argCountForOp =
        let currentLevel = CurrentLevel ()
        let attaching = currentLevel.message

        if attaching = null then
            let condition = IokeObject.As(IokeObject.GetCellChain(runtime.Condition,
                                                                  message,
                                                                  context,
                                                                  [|"Error";
                                                                   "Parser";
                                                                   "OpShuffle"|]), context).Mimic(message, context)
            condition.SetCell("message", message)
            condition.SetCell("context", context)
            condition.SetCell("receiver", context)
            condition.SetCell("text", runtime.NewText("Can't create trinary expression without lvalue"))
            runtime.ErrorCondition(condition)


        // a = b .
        let copyOfMessage = Message.Copy(attaching)

        Message.SetPrev(copyOfMessage, null)
        Message.SetNext(copyOfMessage, null)

        attaching.Arguments.Clear()
        // a = b .  ->  a(a) = b .
        Message.AddArg(attaching, copyOfMessage)

        let expectedArgs = argCountForOp

        // a(a) = b .  ->  =(a) = b .
        Message.SetName(attaching, messageName)

        currentLevel.level <- Attach

        // =(a) = b .
        // =(a) = or =("a") = .
        let mn = Message.GetNext(msg)

        if expectedArgs > 1 then
            // =(a) = b c .  ->  =(a, b c .) = b c .
            Message.AddArg(attaching, mn)

            // process the value (b c d) later  (=(a, b c d) = b c d .)
            if Message.GetNext(msg) <> null && not(Message.IsTerminator(Message.GetNext(msg))) then
                expressions.Insert(0, Message.GetNext(msg))

            let last = find_last msg;
            Message.SetNext(attaching, Message.GetNext(last))
            Message.SetNext(msg, Message.GetNext(last))

            if not(Object.ReferenceEquals(last, msg)) then
                Message.SetNext(last, null)
        else
            Message.SetNext(attaching, Message.GetNext(msg))

    let is_assignment_operation argCountForOp msgArgCount msg =
        argCountForOp <> -1 && (msgArgCount = 0) && not((Message.GetNext(msg) <> null) && Message.GetName(Message.GetNext(msg)).Equals("="))

    let attachMessage (msg : IokeObject) (expressions : IList<IokeObject>) =
        let messageName = Message.GetName(msg)
        let messageSymbol = runtime.GetSymbol(messageName)
        let argCountForOp = argCountForOp messageName messageSymbol msg
        let inverted = isInverted messageSymbol
        let (precedence, msgArgCount) = handle_detach_of_message (handle_unary_prefix_message (levelForOp messageName messageSymbol msg, msg.Arguments.Count) msg) inverted msg

        if is_assignment_operation argCountForOp msgArgCount msg then
            restructure_assignment_operation msgArgCount msg messageName expressions argCountForOp
        elif Message.IsTerminator(msg) then
            popDownTo (OP_LEVEL_MAX-1) expressions
            attachAndReplace (CurrentLevel ()) msg
        elif precedence <> -1 then
            if msgArgCount = 0 then
                popDownTo precedence expressions
                attachToTopAndPush msg precedence
            else
                attachAndReplace (CurrentLevel ()) msg
        else
            attachAndReplace (CurrentLevel ()) msg

    interface IOperatorShuffler with
        member this.Attach(msg, expressions) = attachMessage msg expressions
        member this.NextMessage(expressions) = nextMessage expressions

type FunctionalOperatorShufflerFactory() =
    interface IOperatorShufflerFactory with
        member this.Create(msg, context, message) = new FunctionalOperatorShuffler(msg, context, message) :> IOperatorShuffler


