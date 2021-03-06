require File.dirname(__FILE__) + "/../spec_helper"
FixtureCompiler.require! "exception"
TestException # force dynamic load

=begin # TODO
describe "An Objective-C exception" do
  it "can be catched from Ruby" do
    lambda { TestException.raiseObjCException }.should raise_error
  end
end
=end

# TODO: this is not implemented for i386
if RUBY_ARCH == 'x86_64'
describe "A Ruby exception" do
  it "can be catched from Objective-C" do
    o = Object.new
    def o.raiseRubyException
      raise 'foo'
    end
    TestException.catchRubyException(o).should == 1
  end
end
end
