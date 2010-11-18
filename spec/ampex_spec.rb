require File.dirname(__FILE__) +'/../lib/ampex'
describe "&X" do

  it "should work as Symbol#to_proc" do
    [1,2,3].map(&X.to_s).should == ["1", "2", "3"]
  end

  it "should allow you to pass arguments to methods" do
    [1,"2",3].select(&X.is_a?(String)).should == ["2"]
  end

  it "should work with the [] operator" do
    [{1 => 2}, {1 => 3}].map(&X[1]).should == [2, 3]
  end

  it "should work with unary operators" do
    [1,2,3].map(&-X).should == [-1, -2, -3]
  end

  it "should work with binary operators" do
    ["a", "b", "c"].map(&X * 2).should == ["aa", "bb", "cc"]
  end

  it "should chain methods" do
    [1, 2, 3].map(&X.to_f.to_s).should == ["1.0", "2.0", "3.0"]
  end

  it "should allow assignment" do
    [{}].each(&X['a'] = 1).should == [{'a' => 1}]
  end

  it "should not leak #to_proc" do
    [{}].map(&X['a'] = 1).first.should_not respond_to :to_proc
  end

  it "should not be possible to intercept #to_proc" do
    b = Object.new
    def intercept(b)
      b.respond_to? :to_proc
    end
    [{}].each(&X[intercept(b)] = b).should == [{false => b}]
  end

  it "should preserve existing #to_proc" do
    [{}].each(&X[:to_a] = :to_a).map(&:to_a).should == [[[:to_a, :to_a]]]
  end

  it "should only evaluate arguments once" do
    @counted = 0
    def count
      @counted += 1
    end

    [1, 2, 3].map(&X + count).should == [2, 3, 4]
    @counted.should == 1
  end

  it "shouldn't, but does, make a mess of split assignment" do
    def assigner(key, value); X[key] = value; end
    twoer = assigner(1, 2)
    [{}].each(&twoer).should == [{1 => 2}]
    lambda { [{}, {}].each(&twoer).should == 1 }.should raise_error

    mehier = assigner(1, :inspect)
    [{}].map(&:inspect).should == [:inspect]
  end

  it "should allow you to create lambdas" do
    def assigner(key, value); lambda &X[key] = value; end
    twoer = assigner(1, 2)
    [{}].each(&twoer).should == [{1 => 2}]
    [{}, {}].each(&twoer).should == [{1 => 2}, {1 => 2}]

    mehier = assigner(1, :inspect)
    [{}].map(&:inspect).should == ["{}"]
  end

end
