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

  it "should only evaluate arguments once" do
    @counted = 0
    def count
      @counted += 1
    end

    [1, 2, 3].map(&X + count).should == [2, 3, 4]
    @counted.should == 1
  end

end
