# frozen_string_literal: true

require "test_helper"

class Ractor
  class TMVarTest < Test::Unit::TestCase
    test "VERSION" do
      assert do
        ::Ractor::TMVar.const_defined?(:VERSION)
      end
    end

    test "Ractor::TMVar is empty when created without an initial value" do
      tv = Ractor::TMVar.new
      assert_equal true, tv.empty?
    end

    test "Ractor::TMVar can be filled with nil" do
      tv = Ractor::TMVar.new_filled(nil)
      assert_equal false, tv.empty?
      assert_equal nil, tv.read
      v = nil
      Ractor.atomically do
        v = tv.take
      end
      assert_equal nil, v
      assert_equal true, tv.empty?
    end

    test "Ractor::TMVar roundtrips a non-nil value" do
      tv = Ractor::TMVar.new(:foo)
      assert_equal :foo, tv.read
      v = nil
      Ractor.atomically do
        v = tv.take
      end
      assert_equal :foo, v
      assert_equal true, tv.empty?
    end

    test "Ractor::TMVar can be taken its value" do
      tv = Ractor::TMVar.new(1)
      v = nil
      Ractor.atomically do
        v = tv.take
      end
      assert_equal 1, v
    end

    test "Ractor::TMVar can be changed its value" do
      tv = Ractor::TMVar.new
      v = nil
      Ractor.atomically do
        tv.put :ok
      end
      Ractor.atomically do
        v = tv.take
      end
      assert_equal :ok, v
    end

    test "Ractor::TMVar can avoid deadlock" do
      tv1 = Ractor::TMVar.new(0)
      tv2 = Ractor::TMVar.new(0)
      rs = 100.times.map do
        Ractor.new tv1, tv2 do |v1, v2|
          value1 = nil
          value2 = nil
          Ractor.atomically do
            value1 = v1.take
            value2 = v2.take
          end
          Ractor.atomically do
            v2.put value2 + 2
            v1.put value1 + 1
          end
        end
      end
      rs.each(&:value)
      tv1_value = nil
      tv2_value = nil
      Ractor.atomically do
        tv1_value = tv1.take
        tv2_value = tv2.take
      end
      assert_equal 100, tv1_value
      assert_equal 200, tv2_value
    end

    test "Ractor::TMVar can only read the value" do
      tv = Ractor::TMVar.new(1)
      assert_equal 1, tv.read
    end

    test "Ractor::TMVar try_read returns nil without calling the block when empty" do
      tv = Ractor::TMVar.new
      called = false
      result = tv.try_read { called = true }
      assert_equal nil, result
      assert_equal false, called
    end

    test "Ractor::TMVar try_read yields value and preserves it" do
      tv = Ractor::TMVar.new(5)
      assert_equal(10, tv.try_read { |v| v * 2 })
      assert_equal 5, tv.read
    end

    test "Ractor::TMVar try_read yields nil when filled with nil" do
      tv = Ractor::TMVar.new_filled(nil)
      yielded = nil
      result = tv.try_read do |v|
        yielded = v
        :ok
      end
      assert_equal nil, yielded
      assert_equal :ok, result
      assert_equal false, tv.empty?
    end

    test "Ractor::TMVar try_take returns nil without calling the block when empty" do
      tv = Ractor::TMVar.new
      called = false
      v = :unset
      Ractor.atomically do
        v = tv.try_take { called = true }
      end
      assert_equal nil, v
      assert_equal false, called
      assert_equal true, tv.empty?
    end

    test "Ractor::TMVar try_take yields value and empties first" do
      tv = Ractor::TMVar.new(5)
      v = nil
      Ractor.atomically do
        v = tv.try_take { |value| value * 2 }
      end
      assert_equal 10, v
      assert_equal true, tv.empty?
    end

    test "Ractor::TMVar try_take yields nil when filled with nil" do
      tv = Ractor::TMVar.new_filled(nil)
      yielded = nil
      v = nil
      Ractor.atomically do
        v = tv.try_take do |value|
          yielded = value
          :ok
        end
      end
      assert_equal nil, yielded
      assert_equal :ok, v
      assert_equal true, tv.empty?
    end

    test "Ractor::TMVar try_read and try_take return the value without a block" do
      tv = Ractor::TMVar.new(1)
      assert_equal 1, tv.try_read
      assert_equal false, tv.empty?
      v = nil
      Ractor.atomically { v = tv.try_take }
      assert_equal 1, v
      assert_equal true, tv.empty?
      assert_equal nil, tv.try_read
      Ractor.atomically { v = tv.try_take }
      assert_equal nil, v
    end

    test "Ractor::TMVar try operations accept stored nil without a block" do
      tv = Ractor::TMVar.new(nil)
      assert_equal nil, tv.try_read
      assert_equal false, tv.empty?
      v = :unset
      Ractor.atomically { v = tv.try_take }
      assert_equal nil, v
      assert_equal true, tv.empty?
    end

    test "Ractor::TMVar returns true/false when try_put to empty/full TMVar" do
      tv = Ractor::TMVar.new
      v = true
      Ractor.atomically do
        v = tv.try_put(30)
      end
      assert_equal true, v
      tv = Ractor::TMVar.new(0)
      v = false
      Ractor.atomically do
        v = tv.try_put(30)
      end
      assert_equal false, v
    end

    test "Ractor::TMVar can report its value is now empty or not" do
      tv = Ractor::TMVar.new
      assert_equal true, tv.empty?
      tv = Ractor::TMVar.new(1)
      assert_equal false, tv.empty?
    end

    test "Ractor::TMVar can swap its value" do
      tv = Ractor::TMVar.new(10)
      v = nil
      Ractor.atomically do
        v = tv.swap(20)
      end
      assert_equal 10, v
      Ractor.atomically do
        v = tv.take
      end
      assert_equal 20, v
    end

    test "Ractor::TMVar swap retries when empty" do
      tv = Ractor::TMVar.new
      t = Thread.new do
        sleep 0.1
        Ractor.atomically { tv.put(:late) }
      end
      v = nil
      Ractor.atomically do
        v = tv.swap(:new)
      end
      assert_equal :late, v
      assert_equal :new, tv.read
      t.join
    end
  end
end
