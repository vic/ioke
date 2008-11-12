include_class('ioke.lang.Runtime') { 'IokeRuntime' } unless defined?(IokeRuntime)

describe "Message" do 
  describe "'code'" do 
    it "should return a text representation of itself" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("foo") code').data.text.should == "foo"
    end

    it "should return a text representation of itself with arguments" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("foo(123, 321)") code').data.text.should == "foo(123, 321)"
    end

    it "should return empty parenthesis for the empty message" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("()") code').data.text.should == "()"
    end

    it "should include the next pointer if any exists" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("foo bar") code').data.text.should == "foo bar"
    end
  end

  describe "'name'" do 
    it "should return the name of something simple" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("foo") name').data.text.should == "foo"
    end

    it "should return an empty name" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("()") name').data.text.should == ""
    end

    it "should return a name with a question mark" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("blarg?") name').data.text.should == "blarg?"
    end
  end

  describe "'next'" do 
    it "should return nil if there is no next" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("foo") next').should == ioke.nil
    end

    it "should return the next pointer" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("foo bar") next name').data.text.should == "bar"
      ioke.evaluate_string('Message fromText("foo(123, 321) bar") next name').data.text.should == "bar"
    end
  end
  
  describe "'keyword?'" do 
    it "should return true for a message that ends with a colon" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("foo:") keyword? ').should == ioke.true
      ioke.evaluate_string('Message fromText("bar::::") keyword? ').should == ioke.true
    end

    it "should return false for something simple" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("foo") keyword? ').should == ioke.false
    end

    it "should return false for the empty message" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("()") keyword? ').should == ioke.false
    end
  end

  describe "'sendTo'" do 
    it "should be possible to create a message from text, with arguments and send that to a number" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("+(200)") sendTo(20)').data.as_java_integer.should == 220
    end
    
    it "should possible to send a simple message that is not predefined" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string("f = method(self asText). Message fromText(\"f\") sendTo(42)").data.text.should == "42"
    end
    
    it "should only send one message nad not follow the next pointer" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("+(200) +(10) -(5)") sendTo(20)').data.as_java_integer.should == 220
    end
  end

  describe "'evaluateOn'" do 
    it "should be possible to create a message from text, with arguments and send that to a number" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("+(200)") evaluateOn(20)').data.as_java_integer.should == 220
    end
    
    it "should possible to send a simple message that is not predefined" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string("f = method(self asText). Message fromText(\"f\") evaluateOn(42)").data.text.should == "42"
    end
    
    it "should evaluate the full message chain" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("+(200) +(10) -(5)") evaluateOn(20)').data.as_java_integer.should == 225
    end
  end

  describe "'fromText'" do 
    it "should return a message from the text" do 
      ioke = IokeRuntime.get_runtime
      ioke.evaluate_string('Message fromText("foo")').name.should == "foo"
      ioke.evaluate_string('Message fromText("foo bar")').data.next.name.should == "bar"
    end
  end
end
