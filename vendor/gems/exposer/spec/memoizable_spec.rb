require 'spec_helper'

class MemoTestClass
  include Memoizable

  memoize(:mem_42)    { forty_two }
  memoize(:mem_nil)   { not_an_answer }
  memoize(:mem_false) { i_can_has_cheezburger? }

  memoize(:mem_23, private: true)   { twenty_three }
  memoize(:not_mem_nil, nil: false) { not_an_answer }

  FROZEN_23 = "23".freeze

  def forty_two
    "42"
  end

  def twenty_three
    FROZEN_23
  end

  def not_an_answer
  end

  def i_can_has_cheezburger?
    false
  end

  def get_23
    mem_23
  end
end

RSpec.describe Memoizable do
  subject { MemoTestClass.new }

  it "passes introspection" do
    expect(subject.instance_variables).to be_empty
    expect(subject.public_methods).to include(:mem_42, :mem_nil, :mem_false)
    expect(subject.private_methods).to include(:mem_23)
  end

  it "memoizes non-falsy values" do
    expect(subject).to receive(:forty_two).once.and_call_original
    expect(subject).to receive(:instance_variable_defined?).with(:@mem_42).twice.and_call_original

    expect(subject.mem_42).to eq "42" # (once)
    expect(subject.mem_42).to eq "42" # (twice)
  end

  it "memoizes privately" do
    expect(subject).to receive(:twenty_three).once.and_call_original

    expect { subject.mem_23 }.to raise_error NoMethodError, /private method/
    3.times { expect(subject.get_23).to be MemoTestClass::FROZEN_23 }
    expect(subject.instance_variable_defined? :@mem_23).to be true
  end

  it "memoizes nil values" do
    expect(subject).to receive(:not_an_answer).once.and_call_original

    3.times { expect(subject.mem_nil).to be nil }
    expect(subject.instance_variable_defined? :@mem_nil).to be true
  end

  it "optionally does not memoizes nil values" do
    expect(subject).to receive(:not_an_answer).exactly(3).and_call_original

    3.times { expect(subject.not_mem_nil).to be nil }
    expect(subject.instance_variable_defined? :@not_mem_nil).to be true
    expect(subject.instance_variable_get :@not_mem_nil).to be nil
  end

  it "memoizes false values" do
    expect(subject).to receive(:i_can_has_cheezburger?).once.and_call_original

    3.times { expect(subject.mem_false).to be false }
    expect(subject.instance_variable_defined? :@mem_false).to be true
  end

  it "reloads memoized values" do
    expect(subject).to receive(:forty_two).twice.and_call_original

    expect(subject.mem_42).to eq "42"
    expect(subject.mem_42).to eq "42" # memoized
    expect(subject.mem_42(true)).to eq "42" # reload
    2.times { expect(subject.mem_42).to eq "42" } # again, memoized
  end
end
