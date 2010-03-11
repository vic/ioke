
use("ispec")

parse = method(str,
  Message fromText(str) code)

describe("parsing",
  it("should ignore a first line that starts with #!",
    m = parse("#!/foo/bar 123\nfoo")
    m should == "foo"
  )

  it("should parse an empty string into a terminator message",
    m = parse("")
    m should == ".\n"
  )

  it("should parse a string with only spaces into a terminator message",
    m = parse("  ")
    m should == ".\n"
  )

  describe("terminators",
    it("should parse a newline as a terminator",
      m = parse("\n")
      m should == ".\n"
    )

    it("should parse two newlines as one terminator",
      m = parse("\n\n")
      m should == ".\n"
    )

    it("should parse a period as a terminator",
      m = parse(".")
      m should == ".\n"
    )

    it("should parse one period and one newline as one terminator",
      m = parse(".\n")
      m should == ".\n"
    )

    it("should parse one newline and one period as one terminator",
      m = parse("\n.")
      m should == ".\n"
    )

    it("should parse one newline and one period and one newline as one terminator",
      m = parse("\n.\n")
      m should == ".\n"
    )

    it("should not parse a line ending with a slash as a terminator",
      m = parse("foo\\\nbar")
      m should == "foo bar"
    )

    it("should not parse a line ending with a slash and spaces around it as a terminator",
      m = parse("foo    \\\n    bar")
      m should == "foo bar"
    )
  )

  describe("strings",
    it("should parse a string containing newlines",
      m = parse("\"foo\nbar\"")
      m should == "\"foo\nbar\""
    )

    describe("escapes",
      it("should parse a newline as nothing if preceeded with a slash",
        "foo\
bar" should == "foobar"
      )
    )
  )

  describe("parens without preceeding message",
    it("should be translated into identity message",
      m = parse("(1)")
      m should == "(1)"
    )
  )

  describe("square brackets",
    it("should be parsed correctly in regular message passing syntax",
      m = parse("[]()")
      m should == "[]"
    )

    it("should be parsed correctly in regular message passing syntax with arguments",
      m = parse("[](123)")
      m should == "[](123)"
    )

    it("should be parsed correctly in regular message passing syntax with arguments and receiver",
      m = parse("foo bar(1) [](123)")
      m should == "foo bar(1) [](123)"
    )

    it("should be parsed correctly when empty",
      m = parse("[]")
      m should == "[]"
    )

    it("should be parsed correctly when empty with spaces",
      m = parse("[   ]")
      m should == "[]"
    )

    it("should be parsed correctly with argument",
      m = parse("[1]")
      m should == "[](1)"
    )

    it("should be parsed correctly with argument and spaces",
      m = parse("[   1   ]")
      m should == "[](1)"
    )

    it("should be parsed correctly with arguments",
      m = parse("[1, 2]")
      m should == "[](1, 2)"
    )

    it("should be parsed correctly with terminators inside",
      m = parse("[1, \nfoo(24)]")
      m should == "[](1, foo(24))"
    )

    it("should be parsed correctly directly after an identifier",
      m = parse("foo[1, 2]")
      m should == "foo [](1, 2)"
    )

    it("should be parsed correctly with a space directly after an identifier",
      m = parse("foo [1, 2]")
      m should == "foo [](1, 2)"
    )

    it("should be parsed correctly inside a function application",
      m = parse("foo([1, 2])")
      m should == "foo([](1, 2))"
    )

    it("should not parse correctly when mismatched",
      fn(parse("foo([1, 2)]")) should signal(Condition Error Parser Syntax)
      fn(parse("foo([1, 2)]")) should signalArgument(line: 1)
      fn(parse("foo([1, 2)]")) should signalArgument(character: 8)
      fn(parse("foo([1, 2)]")) should signalArgument(expected: "]")
      fn(parse("foo([1, 2)]")) should signalArgument(got: "')'")
    )

    it("should not parse correctly when missing end",
      fn(parse("[1, 2")) should signal(Condition Error Parser Syntax)
      fn(parse("[1, 2")) should signalArgument(line: 1)
      fn(parse("[1, 2")) should signalArgument(character: 5)
      fn(parse("[1, 2")) should signalArgument(expected: "]")
      fn(parse("[1, 2")) should signalArgument(got: "EOF")
    )
  )

  describe("curly brackets",
    it("should be parsed correctly in regular message passing syntax",
      m = parse("{}()")
      m should == "{}"
    )

    it("should be parsed correctly in regular message passing syntax with arguments",
      m = parse("{}(123)")
      m should == "{}(123)"
    )

    it("should be parsed correctly in regular message passing syntax with arguments and receiver",
      m = parse("foo bar(1) {}(123)")
      m should == "foo bar(1) {}(123)"
    )

    it("should be parsed correctly when empty",
      m = parse("{}")
      m should == "{}"
    )

    it("should be parsed correctly when empty with spaces",
      m = parse("{     }")
      m should == "{}"
    )

    it("should be parsed correctly with argument",
      m = parse("{1}")
      m should == "{}(1)"
    )

    it("should be parsed correctly with argument and spaces",
      m = parse("{ 1     }")
      m should == "{}(1)"
    )

    it("should be parsed correctly with arguments",
      m = parse("{1, 2}")
      m should == "{}(1, 2)"
    )

    it("should be parsed correctly with terminators inside",
      m = parse("{1, \nfoo(24)}")
      m should == "{}(1, foo(24))"
    )

    it("should be parsed correctly directly after an identifier",
      m = parse("foo{1, 2}")
      m should == "foo {}(1, 2)"
    )

    it("should be parsed correctly with a space directly after an identifier",
      m = parse("foo {1, 2}")
      m should == "foo {}(1, 2)"
    )

    it("should be parsed correctly inside a function application",
      m = parse("foo({1, 2})")
      m should == "foo({}(1, 2))"
    )

    it("should not parse correctly when mismatched",
      fn(parse("foo({1, 2)}")) should signal(Condition Error Parser Syntax)
      fn(parse("foo({1, 2)}")) should signalArgument(line: 1)
      fn(parse("foo({1, 2)}")) should signalArgument(character: 8)
      fn(parse("foo({1, 2)}")) should signalArgument(expected: "}")
      fn(parse("foo({1, 2)}")) should signalArgument(got: "')'")
    )

    it("should not parse correctly when missing end",
      fn(parse("{1, 2")) should signal(Condition Error Parser Syntax)
      fn(parse("{1, 2")) should signalArgument(line: 1)
      fn(parse("{1, 2")) should signalArgument(character: 5)
      fn(parse("{1, 2")) should signalArgument(expected: "}")
      fn(parse("{1, 2")) should signalArgument(got: "EOF")
    )
  )

  describe("identifiers",
    it("should be allowed to begin with colon",
      m = parse(":foo")
      m should == ":foo"
    )

    it("should use two colons",
      m = parse("::")
      m should == "::"
    )

    it("should separate two colons",
      m = parse("::foo")
      m should == "::(foo)"
    )

    it("should separate three colons",
      m = parse(":::foo")
      m should == ":::(foo)"
    )

    it("should be allowed to only be a colon",
      m = parse(":")
      m should == ":"
    )

    it("should be allowed to end with colon",
      m = parse("foo:")
      m should == "foo:"
    )

    it("should be allowed to have a colon in the middle",
      m = parse("foo:bar")
      m should == "foo:bar"
    )

    it("should be allowed to have more than one colon in the middle",
      m = parse("foo::bar")
      m should == "foo::bar"

      m = parse("f:o:o:b:a:r")
      m should == "f:o:o:b:a:r"
    )

    it("should be possible to follow a question mark with a colon",
      m = parse("foo?:")
      m should == "foo?:"
    )
  )

  describe("shuffling",
    it("should handle - correctly even if it's not the first line",
      -100 succ should == -99
      -100 succ should == -99
    )

    it("should shuffle a ` without arguments",
      Message fromText("`foo") code should == "`(foo)"
      Message fromText("`42") code should == "`(42)"
      Message fromText("`") code should == "`"
    )

    it("should shuffle a : without arguments",
      Message fromText(":\"42\"") code should == ":(\"42\")"
      Message fromText(": \"42\" 43") code should == ":(\"42\") 43"
    )

    it("should shuffle a ' without arguments",
      Message fromText("'foo") code should == "'(foo)"
      Message fromText("'42") code should == "'(42)"
      Message fromText("'") code should == "'"
    )

    it("should shuffle a '' without arguments",
      Message fromText("''foo") code should == "''(foo)"
      Message fromText("''42") code should == "''(42)"
      Message fromText("''") code should == "''"
    )

    it("should not shuffle a ` with arguments",
      Message fromText("`(foo bar) quux") code should == "`(foo bar) quux"
    )

    it("should not shuffle a : with arguments",
      Message fromText(":(foo)") code should == ":(foo)"
    )

    it("should not shuffle a ' with arguments",
      Message fromText("'(foo bar) quux") code should == "'(foo bar) quux"
    )

    it("should shuffle the arguments to an inverted operator around",
      Message fromText("foo bar quux :: blarg mux") code should == "blarg mux ::(foo bar quux)"
    )

    it("should correctly set message prev/next when suffling unary operators", 
      m = Message fromText("foo 'bar baz")
      m code should == "foo '(bar) baz"
      m name should == :foo
      m next name should == :"'"
      m next arguments length should == 1
      m next arguments first name should == :bar
      m next arguments first prev should be nil
      m next arguments first next should be nil
      m next next name should == :baz
      m next next prev should == m next
    )

    describe("multiple inverted operators in a message chain", 

      it("should shuffle messages correctly",
        m = Message fromText("baz :: bar ::: foo")
        m code should == "foo :::(bar ::(baz))"
      )
      
      it("should not shuffle operators with explicit arguments",
        m = Message fromText("baz :: bar ::(1) ::: foo")
        m code should == "foo :::(bar ::(1) ::(baz))"
      )

      it("should shuffle messages inside arguments", 
        m = Message fromText("baz :: bar(a = 1 + 2, 'foo) ::: foo(4)")
        m code should == "foo(4) :::(bar(=(a, 1 +(2)), '(foo)) ::(baz))"
      )

      it("should shuffle inverted operators inside arguments", 
        m = Message fromText("baz :: bar(a :: b) ::: foo")
        m code should == "foo :::(bar(b ::(a)) ::(baz))"
      )
      
    )
    

  )

  describe("strange characters",
    it("should handle japanese characters correctly",
      キャンディ! = "Candy!"
      キャンディ! should == "Candy!"
    )

    describe("unicode mathematical operator: ∀",
      it("should parse it correctly",
        x = Origin mimic
        x ∀ = method(42)
        x ∀ should == 42
      )
    )

    describe("unicode mathematical operator: ∁",
      it("should parse it correctly",
        x = Origin mimic
        x ∁ = method(42)
        x ∁ should == 42
      )
    )

    describe("unicode mathematical operator: ∂",
      it("should parse it correctly",
        x = Origin mimic
        x ∂ = method(42)
        x ∂ should == 42
      )
    )

    describe("unicode mathematical operator: ∃",
      it("should parse it correctly",
        x = Origin mimic
        x ∃ = method(42)
        x ∃ should == 42
      )
    )

    describe("unicode mathematical operator: ∄",
      it("should parse it correctly",
        x = Origin mimic
        x ∄ = method(42)
        x ∄ should == 42
      )
    )

    describe("unicode mathematical operator: ∅",
      it("should parse it correctly",
        x = Origin mimic
        x ∅ = method(42)
        x ∅ should == 42
      )
    )

    describe("unicode mathematical operator: ∆",
      it("should parse it correctly",
        x = Origin mimic
        x ∆ = method(42)
        x ∆ should == 42
      )
    )

    describe("unicode mathematical operator: ∇",
      it("should parse it correctly",
        x = Origin mimic
        x ∇ = method(42)
        x ∇ should == 42
      )
    )

    describe("unicode mathematical operator: ∈",
      it("should parse it correctly",
        x = Origin mimic
        x cell("∈") = method(v,42)
        (2 ∈ x) should == 42
      )
    )

    describe("unicode mathematical operator: ∉",
      it("should parse it correctly",
        x = Origin mimic
        x cell("∉") = method(v,42)
        (2 ∉ x) should == 42
      )
    )

    describe("unicode mathematical operator: ∊",
      it("should parse it correctly",
        x = Origin mimic
        x ∊ = method(42)
        x ∊ should == 42
      )
    )

    describe("unicode mathematical operator: ∋",
      it("should parse it correctly",
        x = Origin mimic
        x ∋ = method(42)
        x ∋ should == 42
      )
    )

    describe("unicode mathematical operator: ∌",
      it("should parse it correctly",
        x = Origin mimic
        x ∌ = method(42)
        x ∌ should == 42
      )
    )

    describe("unicode mathematical operator: ∍",
      it("should parse it correctly",
        x = Origin mimic
        x ∍ = method(42)
        x ∍ should == 42
      )
    )

    describe("unicode mathematical operator: ∎",
      it("should parse it correctly",
        x = Origin mimic
        x ∎ = method(42)
        x ∎ should == 42
      )
    )

    describe("unicode mathematical operator: ∏",
      it("should parse it correctly",
        x = Origin mimic
        x ∏ = method(42)
        x ∏ should == 42
      )
    )

    describe("unicode mathematical operator: ∐",
      it("should parse it correctly",
        x = Origin mimic
        x ∐ = method(42)
        x ∐ should == 42
      )
    )

    describe("unicode mathematical operator: ∑",
      it("should parse it correctly",
        x = Origin mimic
        x ∑ = method(42)
        x ∑ should == 42
      )
    )

    describe("unicode mathematical operator: −",
      it("should parse it correctly",
        x = Origin mimic
        x − = method(42)
        x − should == 42
      )
    )

    describe("unicode mathematical operator: ∓",
      it("should parse it correctly",
        x = Origin mimic
        x ∓ = method(42)
        x ∓ should == 42
      )
    )

    describe("unicode mathematical operator: ∔",
      it("should parse it correctly",
        x = Origin mimic
        x ∔ = method(42)
        x ∔ should == 42
      )
    )

    describe("unicode mathematical operator: ∕",
      it("should parse it correctly",
        x = Origin mimic
        x ∕ = method(42)
        x ∕ should == 42
      )
    )

    describe("unicode mathematical operator: ∖",
      it("should parse it correctly",
        x = Origin mimic
        x ∖ = method(42)
        x ∖ should == 42
      )
    )

    describe("unicode mathematical operator: ∗",
      it("should parse it correctly",
        x = Origin mimic
        x ∗ = method(42)
        x ∗ should == 42
      )
    )

    describe("unicode mathematical operator: ∘",
      it("should parse it correctly",
        x = Origin mimic
        x ∘ = method(other, 42)
        (x ∘ 5) should == 42
      )
    )

    describe("unicode mathematical operator: ∙",
      it("should parse it correctly",
        x = Origin mimic
        x ∙ = method(42)
        x ∙ should == 42
      )
    )

    describe("unicode mathematical operator: √",
      it("should parse it correctly",
        x = Origin mimic
        x √ = method(42)
        x √ should == 42
      )
    )

    describe("unicode mathematical operator: ∛",
      it("should parse it correctly",
        x = Origin mimic
        x ∛ = method(42)
        x ∛ should == 42
      )
    )

    describe("unicode mathematical operator: ∜",
      it("should parse it correctly",
        x = Origin mimic
        x ∜ = method(42)
        x ∜ should == 42
      )
    )

    describe("unicode mathematical operator: ∝",
      it("should parse it correctly",
        x = Origin mimic
        x ∝ = method(42)
        x ∝ should == 42
      )
    )

    describe("unicode mathematical operator: ∞",
      it("should parse it correctly",
        x = Origin mimic
        x ∞ = method(42)
        x ∞ should == 42
      )
    )

    describe("unicode mathematical operator: ∟",
      it("should parse it correctly",
        x = Origin mimic
        x ∟ = method(42)
        x ∟ should == 42
      )
    )

    describe("unicode mathematical operator: ∠",
      it("should parse it correctly",
        x = Origin mimic
        x ∠ = method(42)
        x ∠ should == 42
      )
    )

    describe("unicode mathematical operator: ∡",
      it("should parse it correctly",
        x = Origin mimic
        x ∡ = method(42)
        x ∡ should == 42
      )
    )

    describe("unicode mathematical operator: ∢",
      it("should parse it correctly",
        x = Origin mimic
        x ∢ = method(42)
        x ∢ should == 42
      )
    )

    describe("unicode mathematical operator: ∣",
      it("should parse it correctly",
        x = Origin mimic
        x ∣ = method(42)
        x ∣ should == 42
      )
    )

    describe("unicode mathematical operator: ∤",
      it("should parse it correctly",
        x = Origin mimic
        x ∤ = method(42)
        x ∤ should == 42
      )
    )

    describe("unicode mathematical operator: ∥",
      it("should parse it correctly",
        x = Origin mimic
        x ∥ = method(42)
        x ∥ should == 42
      )
    )

    describe("unicode mathematical operator: ∦",
      it("should parse it correctly",
        x = Origin mimic
        x ∦ = method(42)
        x ∦ should == 42
      )
    )

    describe("unicode mathematical operator: ∧",
      it("should parse it correctly",
        x = Origin mimic
        x ∧ = method(42)
        x ∧ should == 42
      )
    )

    describe("unicode mathematical operator: ∨",
      it("should parse it correctly",
        x = Origin mimic
        x ∨ = method(42)
        x ∨ should == 42
      )
    )

    describe("unicode mathematical operator: ∩",
      it("should parse it correctly",
        x = Origin mimic
        x ∩ = method(v, 42)
        (x ∩ 2) should == 42
      )
    )

    describe("unicode mathematical operator: ∪",
      it("should parse it correctly",
        x = Origin mimic
        x ∪ = method(v, 42)
        (x ∪ 2) should == 42
      )
    )

    describe("unicode mathematical operator: ∫",
      it("should parse it correctly",
        x = Origin mimic
        x ∫ = method(42)
        x ∫ should == 42
      )
    )

    describe("unicode mathematical operator: ∬",
      it("should parse it correctly",
        x = Origin mimic
        x ∬ = method(42)
        x ∬ should == 42
      )
    )

    describe("unicode mathematical operator: ∭",
      it("should parse it correctly",
        x = Origin mimic
        x ∭ = method(42)
        x ∭ should == 42
      )
    )

    describe("unicode mathematical operator: ∮",
      it("should parse it correctly",
        x = Origin mimic
        x ∮ = method(42)
        x ∮ should == 42
      )
    )

    describe("unicode mathematical operator: ∯",
      it("should parse it correctly",
        x = Origin mimic
        x ∯ = method(42)
        x ∯ should == 42
      )
    )

    describe("unicode mathematical operator: ∰",
      it("should parse it correctly",
        x = Origin mimic
        x ∰ = method(42)
        x ∰ should == 42
      )
    )

    describe("unicode mathematical operator: ∱",
      it("should parse it correctly",
        x = Origin mimic
        x ∱ = method(42)
        x ∱ should == 42
      )
    )

    describe("unicode mathematical operator: ∲",
      it("should parse it correctly",
        x = Origin mimic
        x ∲ = method(42)
        x ∲ should == 42
      )
    )

    describe("unicode mathematical operator: ∳",
      it("should parse it correctly",
        x = Origin mimic
        x ∳ = method(42)
        x ∳ should == 42
      )
    )

    describe("unicode mathematical operator: ∴",
      it("should parse it correctly",
        x = Origin mimic
        x ∴ = method(42)
        x ∴ should == 42
      )
    )

    describe("unicode mathematical operator: ∵",
      it("should parse it correctly",
        x = Origin mimic
        x ∵ = method(42)
        x ∵ should == 42
      )
    )

    describe("unicode mathematical operator: ∶",
      it("should parse it correctly",
        x = Origin mimic
        x ∶ = method(42)
        x ∶ should == 42
      )
    )

    describe("unicode mathematical operator: ∷",
      it("should parse it correctly",
        x = Origin mimic
        x ∷ = method(42)
        x ∷ should == 42
      )
    )

    describe("unicode mathematical operator: ∸",
      it("should parse it correctly",
        x = Origin mimic
        x ∸ = method(42)
        x ∸ should == 42
      )
    )

    describe("unicode mathematical operator: ∹",
      it("should parse it correctly",
        x = Origin mimic
        x ∹ = method(42)
        x ∹ should == 42
      )
    )

    describe("unicode mathematical operator: ∺",
      it("should parse it correctly",
        x = Origin mimic
        x ∺ = method(42)
        x ∺ should == 42
      )
    )

    describe("unicode mathematical operator: ∻",
      it("should parse it correctly",
        x = Origin mimic
        x ∻ = method(42)
        x ∻ should == 42
      )
    )

    describe("unicode mathematical operator: ∼",
      it("should parse it correctly",
        x = Origin mimic
        x ∼ = method(42)
        x ∼ should == 42
      )
    )

    describe("unicode mathematical operator: ∽",
      it("should parse it correctly",
        x = Origin mimic
        x ∽ = method(42)
        x ∽ should == 42
      )
    )

    describe("unicode mathematical operator: ∾",
      it("should parse it correctly",
        x = Origin mimic
        x ∾ = method(42)
        x ∾ should == 42
      )
    )

    describe("unicode mathematical operator: ∿",
      it("should parse it correctly",
        x = Origin mimic
        x ∿ = method(42)
        x ∿ should == 42
      )
    )

    describe("unicode mathematical operator: ≀",
      it("should parse it correctly",
        x = Origin mimic
        x ≀ = method(42)
        x ≀ should == 42
      )
    )

    describe("unicode mathematical operator: ≁",
      it("should parse it correctly",
        x = Origin mimic
        x ≁ = method(42)
        x ≁ should == 42
      )
    )

    describe("unicode mathematical operator: ≂",
      it("should parse it correctly",
        x = Origin mimic
        x ≂ = method(42)
        x ≂ should == 42
      )
    )

    describe("unicode mathematical operator: ≃",
      it("should parse it correctly",
        x = Origin mimic
        x ≃ = method(42)
        x ≃ should == 42
      )
    )

    describe("unicode mathematical operator: ≄",
      it("should parse it correctly",
        x = Origin mimic
        x ≄ = method(42)
        x ≄ should == 42
      )
    )

    describe("unicode mathematical operator: ≅",
      it("should parse it correctly",
        x = Origin mimic
        x ≅ = method(42)
        x ≅ should == 42
      )
    )

    describe("unicode mathematical operator: ≆",
      it("should parse it correctly",
        x = Origin mimic
        x ≆ = method(42)
        x ≆ should == 42
      )
    )

    describe("unicode mathematical operator: ≇",
      it("should parse it correctly",
        x = Origin mimic
        x ≇ = method(42)
        x ≇ should == 42
      )
    )

    describe("unicode mathematical operator: ≈",
      it("should parse it correctly",
        x = Origin mimic
        x ≈ = method(42)
        x ≈ should == 42
      )
    )

    describe("unicode mathematical operator: ≉",
      it("should parse it correctly",
        x = Origin mimic
        x ≉ = method(42)
        x ≉ should == 42
      )
    )

    describe("unicode mathematical operator: ≊",
      it("should parse it correctly",
        x = Origin mimic
        x ≊ = method(42)
        x ≊ should == 42
      )
    )

    describe("unicode mathematical operator: ≋",
      it("should parse it correctly",
        x = Origin mimic
        x ≋ = method(42)
        x ≋ should == 42
      )
    )

    describe("unicode mathematical operator: ≌",
      it("should parse it correctly",
        x = Origin mimic
        x ≌ = method(42)
        x ≌ should == 42
      )
    )

    describe("unicode mathematical operator: ≍",
      it("should parse it correctly",
        x = Origin mimic
        x ≍ = method(42)
        x ≍ should == 42
      )
    )

    describe("unicode mathematical operator: ≎",
      it("should parse it correctly",
        x = Origin mimic
        x ≎ = method(42)
        x ≎ should == 42
      )
    )

    describe("unicode mathematical operator: ≏",
      it("should parse it correctly",
        x = Origin mimic
        x ≏ = method(42)
        x ≏ should == 42
      )
    )

    describe("unicode mathematical operator: ≐",
      it("should parse it correctly",
        x = Origin mimic
        x ≐ = method(42)
        x ≐ should == 42
      )
    )

    describe("unicode mathematical operator: ≑",
      it("should parse it correctly",
        x = Origin mimic
        x ≑ = method(42)
        x ≑ should == 42
      )
    )

    describe("unicode mathematical operator: ≒",
      it("should parse it correctly",
        x = Origin mimic
        x ≒ = method(42)
        x ≒ should == 42
      )
    )

    describe("unicode mathematical operator: ≓",
      it("should parse it correctly",
        x = Origin mimic
        x ≓ = method(42)
        x ≓ should == 42
      )
    )

    describe("unicode mathematical operator: ≔",
      it("should parse it correctly",
        x = Origin mimic
        x ≔ = method(42)
        x ≔ should == 42
      )
    )

    describe("unicode mathematical operator: ≕",
      it("should parse it correctly",
        x = Origin mimic
        x ≕ = method(42)
        x ≕ should == 42
      )
    )

    describe("unicode mathematical operator: ≖",
      it("should parse it correctly",
        x = Origin mimic
        x ≖ = method(42)
        x ≖ should == 42
      )
    )

    describe("unicode mathematical operator: ≗",
      it("should parse it correctly",
        x = Origin mimic
        x ≗ = method(42)
        x ≗ should == 42
      )
    )

    describe("unicode mathematical operator: ≘",
      it("should parse it correctly",
        x = Origin mimic
        x ≘ = method(42)
        x ≘ should == 42
      )
    )

    describe("unicode mathematical operator: ≙",
      it("should parse it correctly",
        x = Origin mimic
        x ≙ = method(42)
        x ≙ should == 42
      )
    )

    describe("unicode mathematical operator: ≚",
      it("should parse it correctly",
        x = Origin mimic
        x ≚ = method(42)
        x ≚ should == 42
      )
    )

    describe("unicode mathematical operator: ≛",
      it("should parse it correctly",
        x = Origin mimic
        x ≛ = method(42)
        x ≛ should == 42
      )
    )

    describe("unicode mathematical operator: ≜",
      it("should parse it correctly",
        x = Origin mimic
        x ≜ = method(42)
        x ≜ should == 42
      )
    )

    describe("unicode mathematical operator: ≝",
      it("should parse it correctly",
        x = Origin mimic
        x ≝ = method(42)
        x ≝ should == 42
      )
    )

    describe("unicode mathematical operator: ≞",
      it("should parse it correctly",
        x = Origin mimic
        x ≞ = method(42)
        x ≞ should == 42
      )
    )

    describe("unicode mathematical operator: ≟",
      it("should parse it correctly",
        x = Origin mimic
        x ≟ = method(42)
        x ≟ should == 42
      )
    )

    describe("unicode mathematical operator: ≠",
      it("should parse it correctly",
        x = Origin mimic
        x ≠ = method(42)
        (x ≠) should == 42
      )
    )

    describe("unicode mathematical operator: ≡",
      it("should parse it correctly",
        x = Origin mimic
        x ≡ = method(42)
        x ≡ should == 42
      )
    )

    describe("unicode mathematical operator: ≢",
      it("should parse it correctly",
        x = Origin mimic
        x ≢ = method(42)
        x ≢ should == 42
      )
    )

    describe("unicode mathematical operator: ≣",
      it("should parse it correctly",
        x = Origin mimic
        x ≣ = method(42)
        x ≣ should == 42
      )
    )

    describe("unicode mathematical operator: ≤",
      it("should parse it correctly",
        x = Origin mimic
        x ≤ = method(42)
        (x ≤) should == 42
      )
    )

    describe("unicode mathematical operator: ≥",
      it("should parse it correctly",
        x = Origin mimic
        x ≥ = method(42)
        (x ≥) should == 42
      )
    )

    describe("unicode mathematical operator: ≦",
      it("should parse it correctly",
        x = Origin mimic
        x ≦ = method(42)
        x ≦ should == 42
      )
    )

    describe("unicode mathematical operator: ≧",
      it("should parse it correctly",
        x = Origin mimic
        x ≧ = method(42)
        x ≧ should == 42
      )
    )

    describe("unicode mathematical operator: ≨",
      it("should parse it correctly",
        x = Origin mimic
        x ≨ = method(42)
        x ≨ should == 42
      )
    )

    describe("unicode mathematical operator: ≩",
      it("should parse it correctly",
        x = Origin mimic
        x ≩ = method(42)
        x ≩ should == 42
      )
    )

    describe("unicode mathematical operator: ≪",
      it("should parse it correctly",
        x = Origin mimic
        x ≪ = method(42)
        x ≪ should == 42
      )
    )

    describe("unicode mathematical operator: ≫",
      it("should parse it correctly",
        x = Origin mimic
        x ≫ = method(42)
        x ≫ should == 42
      )
    )

    describe("unicode mathematical operator: ≬",
      it("should parse it correctly",
        x = Origin mimic
        x ≬ = method(42)
        x ≬ should == 42
      )
    )

    describe("unicode mathematical operator: ≭",
      it("should parse it correctly",
        x = Origin mimic
        x ≭ = method(42)
        x ≭ should == 42
      )
    )

    describe("unicode mathematical operator: ≮",
      it("should parse it correctly",
        x = Origin mimic
        x ≮ = method(42)
        x ≮ should == 42
      )
    )

    describe("unicode mathematical operator: ≯",
      it("should parse it correctly",
        x = Origin mimic
        x ≯ = method(42)
        x ≯ should == 42
      )
    )

    describe("unicode mathematical operator: ≰",
      it("should parse it correctly",
        x = Origin mimic
        x ≰ = method(42)
        x ≰ should == 42
      )
    )

    describe("unicode mathematical operator: ≱",
      it("should parse it correctly",
        x = Origin mimic
        x ≱ = method(42)
        x ≱ should == 42
      )
    )

    describe("unicode mathematical operator: ≲",
      it("should parse it correctly",
        x = Origin mimic
        x ≲ = method(42)
        x ≲ should == 42
      )
    )

    describe("unicode mathematical operator: ≳",
      it("should parse it correctly",
        x = Origin mimic
        x ≳ = method(42)
        x ≳ should == 42
      )
    )

    describe("unicode mathematical operator: ≴",
      it("should parse it correctly",
        x = Origin mimic
        x ≴ = method(42)
        x ≴ should == 42
      )
    )

    describe("unicode mathematical operator: ≵",
      it("should parse it correctly",
        x = Origin mimic
        x ≵ = method(42)
        x ≵ should == 42
      )
    )

    describe("unicode mathematical operator: ≶",
      it("should parse it correctly",
        x = Origin mimic
        x ≶ = method(42)
        x ≶ should == 42
      )
    )

    describe("unicode mathematical operator: ≷",
      it("should parse it correctly",
        x = Origin mimic
        x ≷ = method(42)
        x ≷ should == 42
      )
    )

    describe("unicode mathematical operator: ≸",
      it("should parse it correctly",
        x = Origin mimic
        x ≸ = method(42)
        x ≸ should == 42
      )
    )

    describe("unicode mathematical operator: ≹",
      it("should parse it correctly",
        x = Origin mimic
        x ≹ = method(42)
        x ≹ should == 42
      )
    )

    describe("unicode mathematical operator: ≺",
      it("should parse it correctly",
        x = Origin mimic
        x ≺ = method(42)
        x ≺ should == 42
      )
    )

    describe("unicode mathematical operator: ≻",
      it("should parse it correctly",
        x = Origin mimic
        x ≻ = method(42)
        x ≻ should == 42
      )
    )

    describe("unicode mathematical operator: ≼",
      it("should parse it correctly",
        x = Origin mimic
        x ≼ = method(42)
        x ≼ should == 42
      )
    )

    describe("unicode mathematical operator: ≽",
      it("should parse it correctly",
        x = Origin mimic
        x ≽ = method(42)
        x ≽ should == 42
      )
    )

    describe("unicode mathematical operator: ≾",
      it("should parse it correctly",
        x = Origin mimic
        x ≾ = method(42)
        x ≾ should == 42
      )
    )

    describe("unicode mathematical operator: ≿",
      it("should parse it correctly",
        x = Origin mimic
        x ≿ = method(42)
        x ≿ should == 42
      )
    )

    describe("unicode mathematical operator: ⊀",
      it("should parse it correctly",
        x = Origin mimic
        x ⊀ = method(42)
        x ⊀ should == 42
      )
    )

    describe("unicode mathematical operator: ⊁",
      it("should parse it correctly",
        x = Origin mimic
        x ⊁ = method(42)
        x ⊁ should == 42
      )
    )

    describe("unicode mathematical operator: ⊂",
      it("should parse it correctly",
        x = Origin mimic
        x ⊂ = method(v, 42)
        (x ⊂ 2) should == 42
      )
    )

    describe("unicode mathematical operator: ⊃",
      it("should parse it correctly",
        x = Origin mimic
        x ⊃ = method(v, 42)
        (x ⊃ 2) should == 42
      )
    )

    describe("unicode mathematical operator: ⊄",
      it("should parse it correctly",
        x = Origin mimic
        x ⊄ = method(42)
        x ⊄ should == 42
      )
    )

    describe("unicode mathematical operator: ⊅",
      it("should parse it correctly",
        x = Origin mimic
        x ⊅ = method(42)
        x ⊅ should == 42
      )
    )

    describe("unicode mathematical operator: ⊆",
      it("should parse it correctly",
        x = Origin mimic
        x ⊆ = method(v, 42)
        (x ⊆ 2) should == 42
      )
    )

    describe("unicode mathematical operator: ⊇",
      it("should parse it correctly",
        x = Origin mimic
        x ⊇ = method(v, 42)
        (x ⊇ 2) should == 42
      )
    )

    describe("unicode mathematical operator: ⊈",
      it("should parse it correctly",
        x = Origin mimic
        x ⊈ = method(42)
        x ⊈ should == 42
      )
    )

    describe("unicode mathematical operator: ⊉",
      it("should parse it correctly",
        x = Origin mimic
        x ⊉ = method(42)
        x ⊉ should == 42
      )
    )

    describe("unicode mathematical operator: ⊊",
      it("should parse it correctly",
        x = Origin mimic
        x ⊊ = method(42)
        x ⊊ should == 42
      )
    )

    describe("unicode mathematical operator: ⊋",
      it("should parse it correctly",
        x = Origin mimic
        x ⊋ = method(42)
        x ⊋ should == 42
      )
    )

    describe("unicode mathematical operator: ⊌",
      it("should parse it correctly",
        x = Origin mimic
        x ⊌ = method(42)
        x ⊌ should == 42
      )
    )

    describe("unicode mathematical operator: ⊍",
      it("should parse it correctly",
        x = Origin mimic
        x ⊍ = method(42)
        x ⊍ should == 42
      )
    )

    describe("unicode mathematical operator: ⊎",
      it("should parse it correctly",
        x = Origin mimic
        x ⊎ = method(42)
        x ⊎ should == 42
      )
    )

    describe("unicode mathematical operator: ⊏",
      it("should parse it correctly",
        x = Origin mimic
        x ⊏ = method(42)
        x ⊏ should == 42
      )
    )

    describe("unicode mathematical operator: ⊐",
      it("should parse it correctly",
        x = Origin mimic
        x ⊐ = method(42)
        x ⊐ should == 42
      )
    )

    describe("unicode mathematical operator: ⊑",
      it("should parse it correctly",
        x = Origin mimic
        x ⊑ = method(42)
        x ⊑ should == 42
      )
    )

    describe("unicode mathematical operator: ⊒",
      it("should parse it correctly",
        x = Origin mimic
        x ⊒ = method(42)
        x ⊒ should == 42
      )
    )

    describe("unicode mathematical operator: ⊓",
      it("should parse it correctly",
        x = Origin mimic
        x ⊓ = method(42)
        x ⊓ should == 42
      )
    )

    describe("unicode mathematical operator: ⊔",
      it("should parse it correctly",
        x = Origin mimic
        x ⊔ = method(42)
        x ⊔ should == 42
      )
    )

    describe("unicode mathematical operator: ⊕",
      it("should parse it correctly",
        x = Origin mimic
        x ⊕ = method(42)
        x ⊕ should == 42
      )
    )

    describe("unicode mathematical operator: ⊖",
      it("should parse it correctly",
        x = Origin mimic
        x ⊖ = method(42)
        x ⊖ should == 42
      )
    )

    describe("unicode mathematical operator: ⊗",
      it("should parse it correctly",
        x = Origin mimic
        x ⊗ = method(42)
        x ⊗ should == 42
      )
    )

    describe("unicode mathematical operator: ⊘",
      it("should parse it correctly",
        x = Origin mimic
        x ⊘ = method(42)
        x ⊘ should == 42
      )
    )

    describe("unicode mathematical operator: ⊙",
      it("should parse it correctly",
        x = Origin mimic
        x ⊙ = method(42)
        x ⊙ should == 42
      )
    )

    describe("unicode mathematical operator: ⊚",
      it("should parse it correctly",
        x = Origin mimic
        x ⊚ = method(42)
        x ⊚ should == 42
      )
    )

    describe("unicode mathematical operator: ⊛",
      it("should parse it correctly",
        x = Origin mimic
        x ⊛ = method(42)
        x ⊛ should == 42
      )
    )

    describe("unicode mathematical operator: ⊜",
      it("should parse it correctly",
        x = Origin mimic
        x ⊜ = method(42)
        x ⊜ should == 42
      )
    )

    describe("unicode mathematical operator: ⊝",
      it("should parse it correctly",
        x = Origin mimic
        x ⊝ = method(42)
        x ⊝ should == 42
      )
    )

    describe("unicode mathematical operator: ⊞",
      it("should parse it correctly",
        x = Origin mimic
        x ⊞ = method(42)
        x ⊞ should == 42
      )
    )

    describe("unicode mathematical operator: ⊟",
      it("should parse it correctly",
        x = Origin mimic
        x ⊟ = method(42)
        x ⊟ should == 42
      )
    )

    describe("unicode mathematical operator: ⊠",
      it("should parse it correctly",
        x = Origin mimic
        x ⊠ = method(42)
        x ⊠ should == 42
      )
    )

    describe("unicode mathematical operator: ⊡",
      it("should parse it correctly",
        x = Origin mimic
        x ⊡ = method(42)
        x ⊡ should == 42
      )
    )

    describe("unicode mathematical operator: ⊢",
      it("should parse it correctly",
        x = Origin mimic
        x ⊢ = method(42)
        x ⊢ should == 42
      )
    )

    describe("unicode mathematical operator: ⊣",
      it("should parse it correctly",
        x = Origin mimic
        x ⊣ = method(42)
        x ⊣ should == 42
      )
    )

    describe("unicode mathematical operator: ⊤",
      it("should parse it correctly",
        x = Origin mimic
        x ⊤ = method(42)
        x ⊤ should == 42
      )
    )

    describe("unicode mathematical operator: ⊥",
      it("should parse it correctly",
        x = Origin mimic
        x ⊥ = method(42)
        x ⊥ should == 42
      )
    )

    describe("unicode mathematical operator: ⊦",
      it("should parse it correctly",
        x = Origin mimic
        x ⊦ = method(42)
        x ⊦ should == 42
      )
    )

    describe("unicode mathematical operator: ⊧",
      it("should parse it correctly",
        x = Origin mimic
        x ⊧ = method(42)
        x ⊧ should == 42
      )
    )

    describe("unicode mathematical operator: ⊨",
      it("should parse it correctly",
        x = Origin mimic
        x ⊨ = method(42)
        x ⊨ should == 42
      )
    )

    describe("unicode mathematical operator: ⊩",
      it("should parse it correctly",
        x = Origin mimic
        x ⊩ = method(42)
        x ⊩ should == 42
      )
    )

    describe("unicode mathematical operator: ⊪",
      it("should parse it correctly",
        x = Origin mimic
        x ⊪ = method(42)
        x ⊪ should == 42
      )
    )

    describe("unicode mathematical operator: ⊫",
      it("should parse it correctly",
        x = Origin mimic
        x ⊫ = method(42)
        x ⊫ should == 42
      )
    )

    describe("unicode mathematical operator: ⊬",
      it("should parse it correctly",
        x = Origin mimic
        x ⊬ = method(42)
        x ⊬ should == 42
      )
    )

    describe("unicode mathematical operator: ⊭",
      it("should parse it correctly",
        x = Origin mimic
        x ⊭ = method(42)
        x ⊭ should == 42
      )
    )

    describe("unicode mathematical operator: ⊮",
      it("should parse it correctly",
        x = Origin mimic
        x ⊮ = method(42)
        x ⊮ should == 42
      )
    )

    describe("unicode mathematical operator: ⊯",
      it("should parse it correctly",
        x = Origin mimic
        x ⊯ = method(42)
        x ⊯ should == 42
      )
    )

    describe("unicode mathematical operator: ⊰",
      it("should parse it correctly",
        x = Origin mimic
        x ⊰ = method(42)
        x ⊰ should == 42
      )
    )

    describe("unicode mathematical operator: ⊱",
      it("should parse it correctly",
        x = Origin mimic
        x ⊱ = method(42)
        x ⊱ should == 42
      )
    )

    describe("unicode mathematical operator: ⊲",
      it("should parse it correctly",
        x = Origin mimic
        x ⊲ = method(42)
        x ⊲ should == 42
      )
    )

    describe("unicode mathematical operator: ⊳",
      it("should parse it correctly",
        x = Origin mimic
        x ⊳ = method(42)
        x ⊳ should == 42
      )
    )

    describe("unicode mathematical operator: ⊴",
      it("should parse it correctly",
        x = Origin mimic
        x ⊴ = method(42)
        x ⊴ should == 42
      )
    )

    describe("unicode mathematical operator: ⊵",
      it("should parse it correctly",
        x = Origin mimic
        x ⊵ = method(42)
        x ⊵ should == 42
      )
    )

    describe("unicode mathematical operator: ⊶",
      it("should parse it correctly",
        x = Origin mimic
        x ⊶ = method(42)
        x ⊶ should == 42
      )
    )

    describe("unicode mathematical operator: ⊷",
      it("should parse it correctly",
        x = Origin mimic
        x ⊷ = method(42)
        x ⊷ should == 42
      )
    )

    describe("unicode mathematical operator: ⊸",
      it("should parse it correctly",
        x = Origin mimic
        x ⊸ = method(42)
        x ⊸ should == 42
      )
    )

    describe("unicode mathematical operator: ⊹",
      it("should parse it correctly",
        x = Origin mimic
        x ⊹ = method(42)
        x ⊹ should == 42
      )
    )

    describe("unicode mathematical operator: ⊺",
      it("should parse it correctly",
        x = Origin mimic
        x ⊺ = method(42)
        x ⊺ should == 42
      )
    )

    describe("unicode mathematical operator: ⊻",
      it("should parse it correctly",
        x = Origin mimic
        x ⊻ = method(42)
        x ⊻ should == 42
      )
    )

    describe("unicode mathematical operator: ⊼",
      it("should parse it correctly",
        x = Origin mimic
        x ⊼ = method(42)
        x ⊼ should == 42
      )
    )

    describe("unicode mathematical operator: ⊽",
      it("should parse it correctly",
        x = Origin mimic
        x ⊽ = method(42)
        x ⊽ should == 42
      )
    )

    describe("unicode mathematical operator: ⊾",
      it("should parse it correctly",
        x = Origin mimic
        x ⊾ = method(42)
        x ⊾ should == 42
      )
    )

    describe("unicode mathematical operator: ⊿",
      it("should parse it correctly",
        x = Origin mimic
        x ⊿ = method(42)
        x ⊿ should == 42
      )
    )

    describe("unicode mathematical operator: ⋀",
      it("should parse it correctly",
        x = Origin mimic
        x ⋀ = method(42)
        x ⋀ should == 42
      )
    )

    describe("unicode mathematical operator: ⋁",
      it("should parse it correctly",
        x = Origin mimic
        x ⋁ = method(42)
        x ⋁ should == 42
      )
    )

    describe("unicode mathematical operator: ⋂",
      it("should parse it correctly",
        x = Origin mimic
        x ⋂ = method(42)
        x ⋂ should == 42
      )
    )

    describe("unicode mathematical operator: ⋃",
      it("should parse it correctly",
        x = Origin mimic
        x ⋃ = method(42)
        x ⋃ should == 42
      )
    )

    describe("unicode mathematical operator: ⋄",
      it("should parse it correctly",
        x = Origin mimic
        x ⋄ = method(42)
        x ⋄ should == 42
      )
    )

    describe("unicode mathematical operator: ⋅",
      it("should parse it correctly",
        x = Origin mimic
        x ⋅ = method(42)
        x ⋅ should == 42
      )
    )

    describe("unicode mathematical operator: ⋆",
      it("should parse it correctly",
        x = Origin mimic
        x ⋆ = method(42)
        x ⋆ should == 42
      )
    )

    describe("unicode mathematical operator: ⋇",
      it("should parse it correctly",
        x = Origin mimic
        x ⋇ = method(42)
        x ⋇ should == 42
      )
    )

    describe("unicode mathematical operator: ⋈",
      it("should parse it correctly",
        x = Origin mimic
        x ⋈ = method(42)
        x ⋈ should == 42
      )
    )

    describe("unicode mathematical operator: ⋉",
      it("should parse it correctly",
        x = Origin mimic
        x ⋉ = method(42)
        x ⋉ should == 42
      )
    )

    describe("unicode mathematical operator: ⋊",
      it("should parse it correctly",
        x = Origin mimic
        x ⋊ = method(42)
        x ⋊ should == 42
      )
    )

    describe("unicode mathematical operator: ⋋",
      it("should parse it correctly",
        x = Origin mimic
        x ⋋ = method(42)
        x ⋋ should == 42
      )
    )

    describe("unicode mathematical operator: ⋌",
      it("should parse it correctly",
        x = Origin mimic
        x ⋌ = method(42)
        x ⋌ should == 42
      )
    )

    describe("unicode mathematical operator: ⋍",
      it("should parse it correctly",
        x = Origin mimic
        x ⋍ = method(42)
        x ⋍ should == 42
      )
    )

    describe("unicode mathematical operator: ⋎",
      it("should parse it correctly",
        x = Origin mimic
        x ⋎ = method(42)
        x ⋎ should == 42
      )
    )

    describe("unicode mathematical operator: ⋏",
      it("should parse it correctly",
        x = Origin mimic
        x ⋏ = method(42)
        x ⋏ should == 42
      )
    )

    describe("unicode mathematical operator: ⋐",
      it("should parse it correctly",
        x = Origin mimic
        x ⋐ = method(42)
        x ⋐ should == 42
      )
    )

    describe("unicode mathematical operator: ⋑",
      it("should parse it correctly",
        x = Origin mimic
        x ⋑ = method(42)
        x ⋑ should == 42
      )
    )

    describe("unicode mathematical operator: ⋒",
      it("should parse it correctly",
        x = Origin mimic
        x ⋒ = method(42)
        x ⋒ should == 42
      )
    )

    describe("unicode mathematical operator: ⋓",
      it("should parse it correctly",
        x = Origin mimic
        x ⋓ = method(42)
        x ⋓ should == 42
      )
    )

    describe("unicode mathematical operator: ⋔",
      it("should parse it correctly",
        x = Origin mimic
        x ⋔ = method(42)
        x ⋔ should == 42
      )
    )

    describe("unicode mathematical operator: ⋕",
      it("should parse it correctly",
        x = Origin mimic
        x ⋕ = method(42)
        x ⋕ should == 42
      )
    )

    describe("unicode mathematical operator: ⋖",
      it("should parse it correctly",
        x = Origin mimic
        x ⋖ = method(42)
        x ⋖ should == 42
      )
    )

    describe("unicode mathematical operator: ⋗",
      it("should parse it correctly",
        x = Origin mimic
        x ⋗ = method(42)
        x ⋗ should == 42
      )
    )

    describe("unicode mathematical operator: ⋘",
      it("should parse it correctly",
        x = Origin mimic
        x ⋘ = method(42)
        x ⋘ should == 42
      )
    )

    describe("unicode mathematical operator: ⋙",
      it("should parse it correctly",
        x = Origin mimic
        x ⋙ = method(42)
        x ⋙ should == 42
      )
    )

    describe("unicode mathematical operator: ⋚",
      it("should parse it correctly",
        x = Origin mimic
        x ⋚ = method(42)
        x ⋚ should == 42
      )
    )

    describe("unicode mathematical operator: ⋛",
      it("should parse it correctly",
        x = Origin mimic
        x ⋛ = method(42)
        x ⋛ should == 42
      )
    )

    describe("unicode mathematical operator: ⋜",
      it("should parse it correctly",
        x = Origin mimic
        x ⋜ = method(42)
        x ⋜ should == 42
      )
    )

    describe("unicode mathematical operator: ⋝",
      it("should parse it correctly",
        x = Origin mimic
        x ⋝ = method(42)
        x ⋝ should == 42
      )
    )

    describe("unicode mathematical operator: ⋞",
      it("should parse it correctly",
        x = Origin mimic
        x ⋞ = method(42)
        x ⋞ should == 42
      )
    )

    describe("unicode mathematical operator: ⋟",
      it("should parse it correctly",
        x = Origin mimic
        x ⋟ = method(42)
        x ⋟ should == 42
      )
    )

    describe("unicode mathematical operator: ⋠",
      it("should parse it correctly",
        x = Origin mimic
        x ⋠ = method(42)
        x ⋠ should == 42
      )
    )

    describe("unicode mathematical operator: ⋡",
      it("should parse it correctly",
        x = Origin mimic
        x ⋡ = method(42)
        x ⋡ should == 42
      )
    )

    describe("unicode mathematical operator: ⋢",
      it("should parse it correctly",
        x = Origin mimic
        x ⋢ = method(42)
        x ⋢ should == 42
      )
    )

    describe("unicode mathematical operator: ⋣",
      it("should parse it correctly",
        x = Origin mimic
        x ⋣ = method(42)
        x ⋣ should == 42
      )
    )

    describe("unicode mathematical operator: ⋤",
      it("should parse it correctly",
        x = Origin mimic
        x ⋤ = method(42)
        x ⋤ should == 42
      )
    )

    describe("unicode mathematical operator: ⋥",
      it("should parse it correctly",
        x = Origin mimic
        x ⋥ = method(42)
        x ⋥ should == 42
      )
    )

    describe("unicode mathematical operator: ⋦",
      it("should parse it correctly",
        x = Origin mimic
        x ⋦ = method(42)
        x ⋦ should == 42
      )
    )

    describe("unicode mathematical operator: ⋧",
      it("should parse it correctly",
        x = Origin mimic
        x ⋧ = method(42)
        x ⋧ should == 42
      )
    )

    describe("unicode mathematical operator: ⋨",
      it("should parse it correctly",
        x = Origin mimic
        x ⋨ = method(42)
        x ⋨ should == 42
      )
    )

    describe("unicode mathematical operator: ⋩",
      it("should parse it correctly",
        x = Origin mimic
        x ⋩ = method(42)
        x ⋩ should == 42
      )
    )

    describe("unicode mathematical operator: ⋪",
      it("should parse it correctly",
        x = Origin mimic
        x ⋪ = method(42)
        x ⋪ should == 42
      )
    )

    describe("unicode mathematical operator: ⋫",
      it("should parse it correctly",
        x = Origin mimic
        x ⋫ = method(42)
        x ⋫ should == 42
      )
    )

    describe("unicode mathematical operator: ⋬",
      it("should parse it correctly",
        x = Origin mimic
        x ⋬ = method(42)
        x ⋬ should == 42
      )
    )

    describe("unicode mathematical operator: ⋭",
      it("should parse it correctly",
        x = Origin mimic
        x ⋭ = method(42)
        x ⋭ should == 42
      )
    )

    describe("unicode mathematical operator: ⋮",
      it("should parse it correctly",
        x = Origin mimic
        x ⋮ = method(42)
        x ⋮ should == 42
      )
    )

    describe("unicode mathematical operator: ⋯",
      it("should parse it correctly",
        x = Origin mimic
        x ⋯ = method(42)
        x ⋯ should == 42
      )
    )

    describe("unicode mathematical operator: ⩴",
      it("should parse it correctly",
        x = Origin mimic
        x ⩴ = method(42)
        x ⩴ should == 42
      )
    )

    describe("unicode mathematical operator: ⩵",
      it("should parse it correctly",
        x = Origin mimic
        x ⩵ = method(42)
        x ⩵ should == 42
      )
    )

    describe("unicode mathematical operator: ⩶",
      it("should parse it correctly",
        x = Origin mimic
        x ⩶ = method(42)
        x ⩶ should == 42
      )
    )

    describe("unicode mathematical operator: ⪋",
      it("should parse it correctly",
        x = Origin mimic
        x ⪋ = method(42)
        x ⪋ should == 42
      )
    )

    describe("unicode mathematical operator: ⪌",
      it("should parse it correctly",
        x = Origin mimic
        x ⪌ = method(42)
        x ⪌ should == 42
      )
    )

    describe("unicode mathematical operator: ⪑",
      it("should parse it correctly",
        x = Origin mimic
        x ⪑ = method(42)
        x ⪑ should == 42
      )
    )

    describe("unicode mathematical operator: ⪒",
      it("should parse it correctly",
        x = Origin mimic
        x ⪒ = method(42)
        x ⪒ should == 42
      )
    )

    describe("unicode mathematical operator: ⫅",
      it("should parse it correctly",
        x = Origin mimic
        x ⫅ = method(42)
        x ⫅ should == 42
      )
    )

    describe("unicode mathematical operator: ⫆",
      it("should parse it correctly",
        x = Origin mimic
        x ⫆ = method(42)
        x ⫆ should == 42
      )
    )

    describe("unicode mathematical operator: ⫋",
      it("should parse it correctly",
        x = Origin mimic
        x ⫋ = method(42)
        x ⫋ should == 42
      )
    )

    describe("unicode mathematical operator: ⫌",
      it("should parse it correctly",
        x = Origin mimic
        x ⫌ = method(42)
        x ⫌ should == 42
      )
    )

    describe("unicode mathematical operator: ⫨",
      it("should parse it correctly",
        x = Origin mimic
        x ⫨ = method(42)
        x ⫨ should == 42
      )
    )
  )
)
