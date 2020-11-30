# frozen_string_literal: true

require "test_helper"

class Ractor
  class TMVarTest < Test::Unit::TestCase
    test "VERSION" do
      assert do
        ::Ractor::TMVar.const_defined?(:VERSION)
      end
    end

    test "Ractor::TMVar can has a value" do
      tv = Ractor::TMVar.new(1)
      assert_equal 1, tv.value
    end

    test "Ractor::TMVar without initial value will return nil" do
      tv = Ractor::TMVar.new
      assert_equal nil, tv.value
    end

    test "Ractor::TMVar can change the value" do
      tv = Ractor::TMVar.new
      assert_equal nil, tv.value
      Ractor.atomically do
        tv.value = :ok
      end
      assert_equal :ok, tv.value
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
            value1 = v1.value
            value2 = v2.value
          end
          Ractor.atomically do
            v2.value = value2 + 2
            v1.value = value1 + 1
          end
        end
      end
      rs.each(&:take)
      assert_equal 100, tv1.value
      assert_equal 200, tv2.value
    end
  end
end
