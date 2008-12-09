
use("ispec")

CustomEnumerable = Origin mimic
CustomEnumerable mimic!(Mixins Enumerable)
CustomEnumerable each = macro(
  len = call arguments length
  
  if(len == 1,
    first = call arguments first
    first evaluateOn(call ground, "3first")
    first evaluateOn(call ground, "1second")
    first evaluateOn(call ground, "2third"),

    if(len == 2,
      lexical = LexicalBlock createFrom(call arguments, call ground)
      lexical call("3first")
      lexical call("1second")
      lexical call("2third"),

      lexical = LexicalBlock createFrom(call arguments, call ground)
      lexical call(0, "3first")
      lexical call(1, "1second")
      lexical call(2, "2third"))))

CustomEnumerable2 = Origin mimic
CustomEnumerable2 mimic!(Mixins Enumerable)
CustomEnumerable2 each = macro(
  len = call arguments length
  
  if(len == 1,
    first = call arguments first
    first evaluateOn(call ground, 42)
    first evaluateOn(call ground, 16)
    first evaluateOn(call ground, 17),
    if(len == 2,
      lexical = LexicalBlock createFrom(call arguments, call ground)
      lexical call(42)
      lexical call(16)
      lexical call(17),

      lexical = LexicalBlock createFrom(call arguments, call ground)
      lexical call(0, 42)
      lexical call(1, 16)
      lexical call(2, 17))))

describe(Mixins,
  describe(Mixins Enumerable,
    describe("sort",
      it("should return a sorted list based on all the entries",
        set(4,4,2,1,4,23,6,4,7,21) sort should == [1, 2, 4, 6, 7, 21, 23]
      )
    )

    describe("asList",
      it("should return a list from a list",
        [1,2,3] asList should == [1,2,3]
      )
      
      it("should return a list based on all things yielded to each",
        CustomEnumerable asList should == ["3first", "1second", "2third"]
      )      
    )

    describe("map",
      it("should return an empty list for an empty enumerable",
        [] map(x, x+2) should == []
        {} map(x, x+2) should == []
        set map(x, x+2) should == []
      )
      
      it("should return the same list for something that only returns itself",
        [1, 2, 3] map(x, x) should == [1, 2, 3]
      )

      it("should take one argument and apply the inside",
        [1, 2, 3] map(+2) should == [3, 4, 5]
        [1, 2, 3] map(. 1) should == [1, 1, 1]
      )

      it("should take two arguments and apply the code with the argument name bound",
        [1, 2, 3] map(x, x+3) should == [4, 5, 6]
        [1, 2, 3] map(x, 1) should == [1, 1, 1]
      )      
    )

    describe("mapFn", 
      it("should take zero arguments and just return the elements in a list", 
        [1, 2, 3] mapFn should == [1, 2, 3]
        CustomEnumerable mapFn should == ["3first", "1second", "2third"]
      )
      
      it("should take one lexical block argument and apply that to each element, and return the result in a list", 
        x = fn(arg, arg+2). [1, 2, 3] mapFn(x) should == [3, 4, 5]
        x = fn(arg, arg[0..2])
        CustomEnumerable mapFn(x) should == ["3fi", "1se", "2th"]
      )

      it("should take several lexical blocks and chain them together", 
        x = fn(arg, arg+2). x2 = fn(arg, arg*2). [1, 2, 3] mapFn(x, x2) should == [6, 8, 10]
        x = fn(arg, arg[0..2])
        x2 = fn(arg, arg + "flurg")
        CustomEnumerable mapFn(x, x2) should == ["3fiflurg", "1seflurg", "2thflurg"]
      )
    )
    
    describe("collect", 
      it("should return an empty list for an empty enumerable", 
        [] collect(x, x+2) should == []
        {} collect(x, x+2) should == []
        set collect(x, x+2) should == []
      )
      
      it("should return the same list for something that only returns itself", 
        [1, 2, 3] collect(x, x) should == [1, 2, 3]
      )

      it("should take one argument and apply the inside", 
        [1, 2, 3] collect(+2) should == [3, 4, 5]
        [1, 2, 3] collect(. 1) should == [1, 1, 1]
      )

      it("should take two arguments and apply the code with the argument name bound", 
        [1, 2, 3] collect(x, x+3) should == [4, 5, 6]
        [1, 2, 3] collect(x, 1) should == [1, 1, 1]
      )
    )

    describe("collectFn", 
      it("should take zero arguments and just return the elements in a list", 
        [1, 2, 3] collectFn should == [1, 2, 3]
        CustomEnumerable collectFn should == ["3first", "1second", "2third"]
      )
      
      it("should take one lexical block argument and apply that to each element, and return the result in a list", 
        x = fn(arg, arg+2). [1, 2, 3] collectFn(x) should == [3, 4, 5]
        x = fn(arg, arg[0..2])
        CustomEnumerable collectFn(x) should == ["3fi", "1se", "2th"]
      )

      it("should take several lexical blocks and chain them together", 
        x = fn(arg, arg+2). x2 = fn(arg, arg*2). [1, 2, 3] collectFn(x, x2) should == [6, 8, 10]
        x = fn(arg, arg[0..2])
        x2 = fn(arg, arg + "flurg")
        CustomEnumerable collectFn(x, x2) should == ["3fiflurg", "1seflurg", "2thflurg"]
      )
    )
    
    describe("any?", 
      it("should take zero arguments and just check if any of the values are true", 
        [1,2,3] any?
        [nil,false,nil] any? should == false
        [nil,false,true] any? should == true
        CustomEnumerable any? should == true
      )

      it("should take one argument that is a predicate that is applied to each element in the enumeration", 
        [1,2,3] any?(==2) should == true
        [nil,false,nil] any?(nil?) should == true
        [nil,false,true] any?(==2) should == false
        CustomEnumerable any?(!= "foo") should == true
      )

      it("should take two arguments that will be turned into a lexical block and applied", 
        [1,2,3] any?(x, x==2) should == true
        [nil,false,nil] any?(x, x nil?) should == true
        [nil,false,true] any?(x, x==2) should = =false
        CustomEnumerable any?(x, x != "foo") should == true
      )
    )

    describe("none?", 
      it("should take zero arguments and just check if any of the values are true, and then return false", 
        [1,2,3] none? should == false
        [nil,false,nil] none? should == true
        [nil,false,true] none? should == false
        CustomEnumerable none? should == false
      )

      it("should take one argument that is a predicate that is applied to each element in the enumeration", 
        [1,2,3] none?(==2) should == false
        [nil,false,nil] none?(nil?) should == false
        [nil,false,true] none?(==2) should == true
        CustomEnumerable none?(!= "foo") should == false
      )

      it("should take two arguments that will be turned into a lexical block and applied", 
        [1,2,3] none?(x, x==2) should == false
        [nil,false,nil] none?(x, x nil?) should == false
        [nil,false,true] none?(x, x==2) should == true
        CustomEnumerable none?(x, x != "foo") should == false
      )
    )

    describe("some", 
      it("should take zero arguments and just check if any of the values are true, and then return it", 
        [1,2,3] some should == 1
        [nil,false,nil] some should == false
        [nil,false,true] some should == true
        CustomEnumerable some should == "3first"
      )

      it("should take one argument that is a predicate that is applied to each element in the enumeration", 
        [1,2,3] some(==2 && 3) should == 3
        [nil,false,nil] some(nil? && 42) should == 42
        [nil,false,true] some(==2 && 3) should == false
        CustomEnumerable some(!= "foo" && "blarg") should == "blarg"
      )

      it("should take two arguments that will be turned into a lexical block and applied", 
        [1,2,3] some(x, x==2 && 3) should == 3
        [nil,false,nil] some(x, x nil? && 42) should == 42
        [nil,false,true] some(x, x==2 && 3) should == false
        CustomEnumerable some(x, x != "foo" && "blarg") should == "blarg"
      )
    )

    describe("find", 
      it("should take zero arguments and just check if any of the values are true, and then return it", 
        [1,2,3] find should == 1
        [nil,false,nil] find should == nil
        [nil,false,true] find should == true
        CustomEnumerable find should == "3first"
      )

      it("should take one argument that is a predicate that is applied to each element in the enumeration", 
        [1,2,3] find(==2) should == 2
        [nil,false,nil] find(nil?) should == nil
        [nil,false,true] find(==2) should == nil
        CustomEnumerable find(!= "foo") should == "3first"
      )

      it("should take two arguments that will be turned into a lexical block and applied", 
        [1,2,3] find(x, x==2) should == 2
        [nil,false,nil] find(x, x nil?) should == nil
        [nil,false,true] find(x, x==2) should == nil
        CustomEnumerable find(x, x != "foo") should == "3first"
      )
    )

    describe("detect", 
      it("should take zero arguments and just check if any of the values are true, and then return it", 
        [1,2,3] detect should == 1
        [nil,false,nil] detect should == nil
        [nil,false,true] detect should == true
        CustomEnumerable detect should == "3first"
      )

      it("should take one argument that is a predicate that is applied to each element in the enumeration", 
        [1,2,3] detect(==2) should == 2
        [nil,false,nil] detect(nil?) should == nil
        [nil,false,true] detect(==2) should == nil
        CustomEnumerable detect(!= "foo") should == "3first"
      )

      it("should take two arguments that will be turned into a lexical block and applied", 
        [1,2,3] detect(x, x==2) should == 2
        [nil,false,nil] detect(x, x nil?) should == nil
        [nil,false,true] detect(x, x==2) should == nil
        CustomEnumerable detect(x, x != "foo") should == "3first"
      )
    )


    describe("inject",
      ;; inject needs: a start value, an argument name, a sum argument name, and code
      ;; versions:
      
      ;; inject(+)                                  => inject(    sum,    x,    sum    +(x))
      ;; inject(x, + x)                             => inject(    sumArg, x,    sumArg +(x))
      ;; inject(sumArg, xArg, sumArg + xArg)        => inject(    sumArg, xArg, sumArg + xArg)
      ;; inject("", sumArg, xArg, sumArg + xArg)    => inject("", sumArg, xArg, sumArg +(xArg))

      it("should take one argument that is a message chain and apply that on the sum, with the current arg as argument", 
        [1,2,3] inject(+) should == 6
        [1,2,3] inject(*(5) -) should == 12
        CustomEnumerable2 inject(-) should == 9
      )

      it("should take two arguments that is an argument name and a message chain and apply that on the sum", 
        [1,2,3] inject(x, + x*2) should == 11
        [1,2,3] inject(x, *(5) - x) should == 12
        CustomEnumerable2 inject(x, - x) should == 9
      )

      it("should take three arguments that is the sum name, the argument name and code to apply", 
        [1,2,3] inject(sum, x, sum + x*2) should == 11
        [1,2,3] inject(sum, x, sum *(5) - x) should == 12
        CustomEnumerable2 inject(sum, x, sum - x) should == 9
      )

      it("should take four arguments that is the initial value, the sum name, the argument name and code to apply", 
        [1,2,3] inject(13, sum, x, sum + x*2) should == 25
        [1,2,3] inject(1, sum, x, sum *(5) - x) should == 87
        CustomEnumerable2 inject(100, sum, x, sum - x) should == 25
      )
    )    

    describe("reduce",
      ;; reduce needs: a start value, an argument name, a sum argument name, and code
      ;; versions:
      
      ;; reduce(+)                                  => reduce(    sum,    x,    sum    +(x))
      ;; reduce(x, + x)                             => reduce(    sumArg, x,    sumArg +(x))
      ;; reduce(sumArg, xArg, sumArg + xArg)        => reduce(    sumArg, xArg, sumArg + xArg)
      ;; reduce("", sumArg, xArg, sumArg + xArg)    => reduce("", sumArg, xArg, sumArg +(xArg))

      it("should take one argument that is a message chain and apply that on the sum, with the current arg as argument", 
        [1,2,3] reduce(+) should == 6
        [1,2,3] reduce(*(5) -) should == 12
        CustomEnumerable2 reduce(-) should == 9
      )

      it("should take two arguments that is an argument name and a message chain and apply that on the sum", 
        [1,2,3] reduce(x, + x*2) should == 11
        [1,2,3] reduce(x, *(5) - x) should == 12
        CustomEnumerable2 reduce(x, - x) should == 9
      )

      it("should take three arguments that is the sum name, the argument name and code to apply", 
        [1,2,3] reduce(sum, x, sum + x*2) should == 11
        [1,2,3] reduce(sum, x, sum *(5) - x) should == 12
        CustomEnumerable2 reduce(sum, x, sum - x) should == 9
      )

      it("should take four arguments that is the initial value, the sum name, the argument name and code to apply", 
        [1,2,3] reduce(13, sum, x, sum + x*2) should == 25
        [1,2,3] reduce(1, sum, x, sum *(5) - x) should == 87
        CustomEnumerable2 reduce(100, sum, x, sum - x) should == 25
      )
    )    

    describe("fold",
      ;; fold needs: a start value, an argument name, a sum argument name, and code
      ;; versions:
      
      ;; fold(+)                                  => fold(    sum,    x,    sum    +(x))
      ;; fold(x, + x)                             => fold(    sumArg, x,    sumArg +(x))
      ;; fold(sumArg, xArg, sumArg + xArg)        => fold(    sumArg, xArg, sumArg + xArg)
      ;; fold("", sumArg, xArg, sumArg + xArg)    => fold("", sumArg, xArg, sumArg +(xArg))

      it("should take one argument that is a message chain and apply that on the sum, with the current arg as argument", 
        [1,2,3] fold(+) should == 6
        [1,2,3] fold(*(5) -) should == 12
        CustomEnumerable2 fold(-) should == 9
      )

      it("should take two arguments that is an argument name and a message chain and apply that on the sum", 
        [1,2,3] fold(x, + x*2) should == 11
        [1,2,3] fold(x, *(5) - x) should == 12
        CustomEnumerable2 fold(x, - x) should == 9
      )

      it("should take three arguments that is the sum name, the argument name and code to apply", 
        [1,2,3] fold(sum, x, sum + x*2) should == 11
        [1,2,3] fold(sum, x, sum *(5) - x) should == 12
        CustomEnumerable2 fold(sum, x, sum - x) should == 9
      )

      it("should take four arguments that is the initial value, the sum name, the argument name and code to apply", 
        [1,2,3] fold(13, sum, x, sum + x*2) should == 25
        [1,2,3] fold(1, sum, x, sum *(5) - x) should == 87
        CustomEnumerable2 fold(100, sum, x, sum - x) should == 25
      )
    )
    
    describe("flatMap", 
      it("should return a correct flattened map", 
        [1,2,3] flatMap(x, [x]) should == [1,2,3]
        [1,2,3] flatMap(x, [x, x+10, x+20]) should == [1,11,21,2,12,22,3,13,23]
        [4,5,6] flatMap(x, [x+20, x+10, x]) should == [24,14,4,25,15,5,26,16,6]
      )
    )
    
    describe("select", 
      it("should take zero arguments and return a list with only the true values", 
        [1,2,3] select should == [1,2,3]
        [nil,false,nil] select should == []
        [nil,false,true] select should == [true]
        CustomEnumerable select should == CustomEnumerable asList
      )

      it("should take one argument that ends up being a predicate and return a list of the values that is true", 
        [1,2,3] select(>1) should == [2,3]
        [nil,false,nil] select(nil?) should == [nil, nil]
        [nil,false,true] select(==2) should == []
        CustomEnumerable select([0...1] != "1") should == ["3first", "2third"]
      )

      it("should take two arguments that ends up being a predicate and return a list of the values that is true", 
        [1,2,3] select(x, x>1) should == [2,3]
        [nil,false,nil] select(x, x nil?) should == [nil, nil]
        [nil,false,true] select(x, x==2) should == []
        CustomEnumerable select(x, x != "2third") should == ["3first", "1second"]
      )
    )

    describe("findAll", 
      it("should take zero arguments and return a list with only the true values", 
        [1,2,3] findAll should == [1,2,3]
        [nil,false,nil] findAll should == []
        [nil,false,true] findAll should == [true]
        CustomEnumerable findAll should == CustomEnumerable asList
      )

      it("should take one argument that ends up being a predicate and return a list of the values that is true", 
        [1,2,3] findAll(>1) should == [2,3]
        [nil,false,nil] findAll(nil?) should == [nil, nil]
        [nil,false,true] findAll(==2) should == []
        CustomEnumerable findAll([0...1] != "1") should == ["3first", "2third"]
      )

      it("should take two arguments that ends up being a predicate and return a list of the values that is true", 
        [1,2,3] findAll(x, x>1) should == [2,3]
        [nil,false,nil] findAll(x, x nil?) should == [nil, nil]
        [nil,false,true] findAll(x, x==2) should == []
        CustomEnumerable findAll(x, x != "2third") should == ["3first", "1second"]
      )
    )

    describe("filter", 
      it("should take zero arguments and return a list with only the true values", 
        [1,2,3] filter should == [1,2,3]
        [nil,false,nil] filter should == []
        [nil,false,true] filter should == [true]
        CustomEnumerable filter should == CustomEnumerable asList
      )

      it("should take one argument that ends up being a predicate and return a list of the values that is true", 
        [1,2,3] filter(>1) should == [2,3]
        [nil,false,nil] filter(nil?) should == [nil, nil]
        [nil,false,true] filter(==2) should == []
        CustomEnumerable filter([0...1] != "1") should == ["3first", "2third"]
      )

      it("should take two arguments that ends up being a predicate and return a list of the values that is true", 
        [1,2,3] filter(x, x>1) should == [2,3]
        [nil,false,nil] filter(x, x nil?) should == [nil, nil]
        [nil,false,true] filter(x, x==2) should == []
        CustomEnumerable filter(x, x != "2third") should == ["3first", "1second"]
      )
    )
    
    describe("all?", 
      it("should take zero arguments and just check if all of the values are true", 
        [1,2,3] all? should == true
        [nil,false,nil] all? should == false
        [nil,false,true] all? should == false
        CustomEnumerable all? should == true
      )

      it("should take one argument that is a predicate that is applied to each element in the enumeration", 
        [1,2,3] all?(==2) should == false
        [1,2,3] all?(>0) should == true
        [nil,false,nil] all?(nil?) should == false
        [nil,false,true] all?(==2) should == false
        CustomEnumerable all?(!= "foo") should == true
      )

      it("should take two arguments that will be turned into a lexical block and applied", 
        [1,2,3] all?(x, x==2) should == false
        [1,2,3] all?(x, x<4) should == true
        [nil,false,nil] all?(x, x nil?) should == false
        [nil,nil,nil] all?(x, x nil?) should == true
        [nil,false,true] all?(x, x==2) should == false
        CustomEnumerable all?(x, x != "foo") should == true
      )
    )
    
    describe("count", 
      it("should take zero arguments and return how many elements there are", 
        [1,2,3] count should == 3
        [nil,false] count should == 2
        [nil,false,true] count should == 3
        CustomEnumerable count should == 3
      )

      it("should take one element that is a predicate, and return how many matches it", 
        [1,2,3] count(>1) should == 2
        [nil,false,nil] count(nil?) should == 2
        [nil,false,true] count(==2) should == 0
        CustomEnumerable count([0...1] != "1") should == 2
      )

      it("should take two elements that turn into a lexical block and returns how many matches it", 
        [1,2,3] count(x, x>1) should == 2
        [nil,false,nil] count(x, x nil?) should == 2
        [nil,false,true] count(x, x==2) should == 0
        CustomEnumerable count(x, x != "2third") should == 2
      )
    )

    describe("reject", 
      it("should take one argument that ends up being a predicate and return a list of the values that is false", 
        [1,2,3] reject(>1) should == [1]
        [nil,false,nil] reject(nil?) should == [false]
        [nil,false,true] reject(==2) should == [nil,false,true]
        CustomEnumerable reject([0...1] == "1") should == ["3first", "2third"]
      )

      it("should take two arguments that ends up being a predicate and return a list of the values that is false", 
        [1,2,3] reject(x, x>1) should == [1]
        [nil,false,nil] reject(x, x nil?) should == [false]
        [nil,false,true] reject(x, x==2) should == [nil,false,true]
        CustomEnumerable reject(x, x == "2third") should == ["3first", "1second"]
      )
    )
    
    describe("first", 
      it("should return nil for an empty collection", 
        set first should == nil
      )

      it("should take an optional argument of how many to return", 
        set first(0) should == []
        set first(1) should == []
        set first(2) should == []
      )
      
      it("should return the first element for a non-empty collection", 
        set(42) first should == 42
        CustomEnumerable first should == "3first"
      )
      
      it("should return the first n elements for a non-empty collection", 
        set(42) first(0) should == []
        set(42) first(1) should == [42]
        set(42) first(2) should == [42]
        [42, 44, 46] first(2) should == [42, 44]
        set(42, 44, 46) first(3) sort should == [42, 44, 46]
        CustomEnumerable first(2) should == ["3first", "1second"]
      )
    )
  )
)
