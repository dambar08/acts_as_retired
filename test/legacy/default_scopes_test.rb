# frozen_string_literal: true

require "test_helper"

class MultipleDefaultScopesTest < ActiveSupport::TestCase
  class ParanoidPolygon < ActiveRecord::Base
    acts_as_retired
    default_scope { where("sides = ?", 3) }
  end

  def setup
    ActiveRecord::Schema.define(version: 1) do
      create_table :paranoid_polygons do |t|
        t.integer :sides
        t.datetime :retired_at

        timestamps t
      end
    end

    ParanoidPolygon.create! sides: 3
    ParanoidPolygon.create! sides: 3
    ParanoidPolygon.create! sides: 3
    ParanoidPolygon.create! sides: 8

    assert_equal 3, ParanoidPolygon.count
    assert_equal 4, ParanoidPolygon.unscoped.count
  end

  def teardown
    teardown_db
  end

  def test_only_deleted_with_retired_with_multiple_default_scope
    3.times { ParanoidPolygon.create! sides: 3 }
    ParanoidPolygon.create! sides: 8
    ParanoidPolygon.first.destroy

    assert_equal 1, ParanoidPolygon.only_retired.count
    assert_equal 1, ParanoidPolygon.only_retired.with_retired.count
  end

  def test_with_retired_only_deleted_with_multiple_default_scope
    3.times { ParanoidPolygon.create! sides: 3 }
    ParanoidPolygon.create! sides: 8
    ParanoidPolygon.first.destroy

    assert_equal 1, ParanoidPolygon.only_retired.count
    assert_equal 1, ParanoidPolygon.with_retired.only_retired.count
  end

  def test_fake_removal_with_multiple_default_scope
    ParanoidPolygon.first.destroy

    assert_equal 2, ParanoidPolygon.count
    assert_equal 3, ParanoidPolygon.with_retired.count
    assert_equal 1, ParanoidPolygon.only_retired.count
    assert_equal 4, ParanoidPolygon.unscoped.count

    ParanoidPolygon.destroy_all

    assert_equal 0, ParanoidPolygon.count
    assert_equal 3, ParanoidPolygon.with_retired.count
    assert_equal 3, ParanoidPolygon.with_retired.count
    assert_equal 4, ParanoidPolygon.unscoped.count
  end

  def test_real_removal_with_multiple_default_scope
    # two-step
    ParanoidPolygon.first.destroy
    ParanoidPolygon.only_retired.first.destroy

    assert_equal 2, ParanoidPolygon.count
    assert_equal 2, ParanoidPolygon.with_retired.count
    assert_equal 0, ParanoidPolygon.only_retired.count
    assert_equal 3, ParanoidPolygon.unscoped.count

    ParanoidPolygon.first.destroy_fully!

    assert_equal 1, ParanoidPolygon.count
    assert_equal 1, ParanoidPolygon.with_retired.count
    assert_equal 0, ParanoidPolygon.only_retired.count
    assert_equal 2, ParanoidPolygon.unscoped.count

    ParanoidPolygon.retire_all!

    assert_equal 0, ParanoidPolygon.count
    assert_equal 0, ParanoidPolygon.with_retired.count
    assert_equal 0, ParanoidPolygon.only_retired.count
    assert_equal 1, ParanoidPolygon.unscoped.count
  end
end
