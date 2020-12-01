# frozen_string_literal: true

require "test_helper"

class Ractor
  class TMVarTest < Test::Unit::TestCase
    test "VERSION" do
      assert do
        ::Ractor::TMVar.const_defined?(:VERSION)
      end
    end

    test "Ractor::TMVar can be taken its value" do
      tv = Ractor::TMVar.new(1)
      v = nil
      Ractor.atomically do
        v = tv.take
      end
      assert_equal 1, v
    end

    test "Ractor::TMVar without initial value will return nil" do
      tv = Ractor::TMVar.new
      v = nil
      Ractor.atomically do
        v = tv.take
      end
      assert_equal nil, v
    end

    test "Ractor::TMVar can be changed its value" do
      tv = Ractor::TMVar.new
      v = nil
      Ractor.atomically do
        v = tv.take
      end
      assert_equal nil, v
      Ractor.atomically do
        tv.put :ok
      end
      Ractor.atomically do
        v = tv.take
      end
      assert_equal :ok, v
    end

    test "Ractor::TMVar can not set the unshareable value" do
      assert_raise ArgumentError do
        Ractor::TMVar.new [1]
      end
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
      rs.each(&:take)
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

    test "Ractor::TMVar returns nil when try_read to EMPTY TMVar" do
      tv = Ractor::TMVar.new(1)
      assert_equal 1, tv.read
      tv = Ractor::TMVar.new(Ractor::TMVar::EMPTY)
      assert_equal nil, tv.try_read
    end

    test "Ractor::TMVar returns nil when try_take to EMPTY TMVar" do
      tv = Ractor::TMVar.new(Ractor::TMVar::EMPTY)
      v = nil
      Ractor.atomically do
        v = tv.try_take
      end
      assert_equal nil, v
    end

    test "Ractor::TMVar returns true/false when try_put to EMPTY/not-EMPTY TMVar" do
      tv = Ractor::TMVar.new
      v = true
      Ractor.atomically do
        v = tv.try_put(30)
      end
      assert_equal false, v
      tv = Ractor::TMVar.new(Ractor::TMVar::EMPTY)
      v = false
      Ractor.atomically do
        v = tv.try_put(30)
      end
      assert_equal true, v
    end

    test "Ractor::TMVar can report its value is now empty or not" do
      tv = Ractor::TMVar.new(Ractor::TMVar::EMPTY)
      assert_equal true, tv.empty?
      tv = Ractor::TMVar.new
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
  end
end
