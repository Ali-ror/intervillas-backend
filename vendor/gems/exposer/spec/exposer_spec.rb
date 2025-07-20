require 'spec_helper'

class ExpoTestClass
  include Exposer

  def self.helper_method(name)
    @helper_methods ||= []
    @helper_methods << name.to_s
  end

  expose(:ed25519)            { get_ed25519 }
  expose(:nilval, nil: true)  { get_nilval }
end

describe Exposer do
  let(:ed25519_precomputed) { 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed }

  subject { ExpoTestClass.new }

  it "passes introspection" do
    expect(subject.public_methods).not_to include(:ed25519, :nilval)
    expect(subject.private_methods).to    include(:ed25519, :nilval)
    expect(ExpoTestClass.instance_variable_get(:@helper_methods)).to include("ed25519", "nilval")
  end

  it "exposes a large number" do
    expect(subject).to receive(:get_ed25519).once.and_return(2**255 - 19)

    expect(subject.send(:ed25519)                  ).to eq ed25519_precomputed
    expect(subject.send(:ed25519)                  ).to eq ed25519_precomputed
    expect(subject.instance_variable_get(:@ed25519)).to eq ed25519_precomputed
  end

  it "can memoize nil values" do
    expect(subject).to receive(:get_nilval).once

    expect(subject.send(:nilval)                  ).to be nil
    expect(subject.send(:nilval)                  ).to be nil
    expect(subject.instance_variable_get(:@nilval)).to be nil
  end
end
