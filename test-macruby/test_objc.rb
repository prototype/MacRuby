#!/usr/bin/env macruby

require 'test/unit'

require 'test/unit'
class Test::Unit::TestCase
  class << self
    def it(name, &block)
      define_method("test_#{name}", &block)
    end
  end
end

class TestClassConstantLookup < Test::Unit::TestCase
  module Namespace
    class PureRubyClass; end
    module PureRubyModule; end
    SINGLETON = (class << self; self; end)
  end
  
  it "should not find pure Ruby classes in different namespaces" do
    assert_raise(NameError) { PureRubyClass }
  end
  
  it "should find pure Ruby classes in different namespaces if given the correct path" do
    assert_nothing_raised(NameError) { Namespace::PureRubyClass }
  end
  
  it "should not find pure Ruby modules in different namespaces" do
    assert_raise(NameError) { PureRubyModule }
  end
  
  it "should find pure Ruby modules in different namespaces if given the correct path" do
    assert_nothing_raised(NameError) { Namespace::PureRubyModule }
  end
  
  it "should not find pure Ruby class singletons in different namespaces" do
    assert_raise(NameError) { SINGLETON }
  end
  
  it "should find pure Ruby class singletons in different namespaces if given the correct path" do
    assert_nothing_raised(NameError) { Namespace::SINGLETON }
  end
end

class TestSubclass < Test::Unit::TestCase

  def setup
    framework 'Foundation'
    bundle = '/tmp/_test.bundle'
    if !File.exist?(bundle) or File.mtime(bundle) < File.mtime(__FILE__)
      s = <<EOS
#import <Foundation/Foundation.h>
@interface MyClass : NSObject
@end
@implementation MyClass
- (int)test
{
    return 42;
}
- (id)test_getObject:(id)dictionary forKey:(id)key
{
  return [dictionary objectForKey:key];
}
@end
EOS
      File.open('/tmp/_test.m', 'w') { |io| io.write(s) }
      system("gcc /tmp/_test.m -bundle -o #{bundle} -framework Foundation -fobjc-gc-only") or exit 1
    end
    require 'dl'; DL.dlopen(bundle)
  end

  def test_new
    o = NSObject.new
    assert_kind_of(NSObject, o)
    o = NSObject.alloc.init
    assert_kind_of(NSObject, o)
  end

  class MyDictionary < NSMutableDictionary
    def foo(tc, *args)
      tc.assert_kind_of(Array, args)
      unless args.empty?
        tc.assert_equal(1, args.length)
        tc.assert_kind_of(Hash, args[0])
      end
    end
    def foo2(tc, args)
      tc.assert_kind_of(Hash, args)
    end
  end

  def test_keyed_syntax
    d = NSMutableDictionary.new
    o = NSObject.new
    k = NSString.new
    d.setObject o, forKey:k
    assert_equal(o, d.objectForKey(k))

    d2 = MyDictionary.new
    d2.foo(self)
    d2.foo(self, foo:k)
    d2.foo(self, foo:k, bar:k)
    d2.foo2(self, foo:k, bar:k)

    d2 = NSMutableDictionary.performSelector('new')
    d2.performSelector(:'setObject:forKey:', withObject:o, withObject:k)
    assert_equal(o, d2.performSelector(:'objectForKey:', withObject:k))
    assert(d.isEqual(d2))
  end

  def test_pure_objc_ivar
    o = NSObject.alloc.init
    assert_kind_of(NSObject, o)
    o.instance_variable_set(:@foo, 'foo')
    GC.start
    assert_equal('foo', o.instance_variable_get(:@foo))
  end

  def test_cftype_ivar
    o = NSString.alloc.init
    assert_kind_of(NSString, o)
    o.instance_variable_set(:@foo, 'foo')
    GC.start
    assert_equal('foo', o.instance_variable_get(:@foo))
  end

  def test_method_dispatch_priority
    o = MyClass.new
    assert_kind_of(MyClass, o)
    assert_equal(42, o.test)
  end

  def test_method_variadic
    p = NSPredicate.predicateWithFormat('foo == 1')
    assert_kind_of(NSPredicate, p)
    p = NSPredicate.predicateWithFormat('foo == %@', 'bar')
    assert_kind_of(NSPredicate, p)
    p = NSPredicate.predicateWithFormat('%@ == %@', 'foo', 'bar')
    assert_kind_of(NSPredicate, p)
  end

  def test_primitive_as_dictionary_key
    o = MyClass.new
    assert_kind_of(MyClass, o)
    s = String.new("foo")
    v = Object.new
    dict = {s => v}
    assert_equal(v, o.test_getObject(dict, forKey:s))
    dict = {}
    dict.setObject v, forKey:s
    assert_equal(v, o.test_getObject(dict, forKey:s))
  end

end
