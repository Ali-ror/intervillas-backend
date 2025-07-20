require "spec_helper"

class A
  def a
    :a
  end
end

class B < A
  include Memoizable
  memoize(:a) { :b }
end

class C < B
  memoize(:a) { :c }
end

class D < B
end

RSpec.describe "Inheritance and shadowing" do
  it "overwrites normal method definitions" do
    expect(B.new.a).to be :b
  end

  it "overwrites memoized methods" do
    expect(C.new.a).to be :c
  end

  it "inherits memoized methods" do
    expect(D.new.a).to be :b
  end
end
