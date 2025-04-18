# frozen_string_literal: true

require "test_helper"

class RelationsTest < ActiveSupport::TestCase
  class ParanoidForest < ActiveRecord::Base
    acts_as_retired

    scope :rainforest, -> { where(rainforest: true) }

    has_many :paranoid_trees, dependent: :destroy
  end

  class ParanoidTree < ActiveRecord::Base
    acts_as_retired
    belongs_to :paranoid_forest
    validates_presence_of :name
  end

  class NotParanoidBowl < ActiveRecord::Base
    has_many :paranoid_chocolates, dependent: :destroy
  end

  class ParanoidChocolate < ActiveRecord::Base
    acts_as_retired
    belongs_to :not_paranoid_bowl
    validates_presence_of :name
  end

  def setup
    ActiveRecord::Schema.define(version: 1) do
      create_table :paranoid_forests do |t|
        t.string   :name
        t.boolean  :rainforest
        t.datetime :retired_at

        timestamps t
      end

      create_table :paranoid_trees do |t|
        t.integer  :paranoid_forest_id
        t.string   :name
        t.datetime :retired_at

        timestamps t
      end

      create_table :not_paranoid_bowls do |t|
        t.string   :name

        timestamps t
      end

      create_table :paranoid_chocolates do |t|
        t.integer  :not_paranoid_bowl_id
        t.string   :name
        t.datetime :retired_at

        timestamps t
      end
    end

    @paranoid_forest_1 = ParanoidForest.create! name: "ParanoidForest #1"
    @paranoid_forest_2 = ParanoidForest.create! name: "ParanoidForest #2", rainforest: true
    @paranoid_forest_3 = ParanoidForest.create! name: "ParanoidForest #3", rainforest: true

    assert_equal 3, ParanoidForest.count
    assert_equal 2, ParanoidForest.rainforest.count

    @paranoid_forest_1.paranoid_trees.create! name: "ParanoidTree #1"
    @paranoid_forest_1.paranoid_trees.create! name: "ParanoidTree #2"
    @paranoid_forest_2.paranoid_trees.create! name: "ParanoidTree #3"
    @paranoid_forest_2.paranoid_trees.create! name: "ParanoidTree #4"

    assert_equal 4, ParanoidTree.count
  end

  def teardown
    teardown_db
  end

  def test_filtering_with_scopes
    assert_equal 2, ParanoidForest.rainforest.with_retired.count
    assert_equal 2, ParanoidForest.with_retired.rainforest.count

    assert_equal 0, ParanoidForest.rainforest.only_retired.count
    assert_equal 0, ParanoidForest.only_retired.rainforest.count

    ParanoidForest.rainforest.first.destroy

    assert_equal 1, ParanoidForest.rainforest.count

    assert_equal 2, ParanoidForest.rainforest.with_retired.count
    assert_equal 2, ParanoidForest.with_retired.rainforest.count

    assert_equal 1, ParanoidForest.rainforest.only_retired.count
    assert_equal 1, ParanoidForest.only_retired.rainforest.count
  end

  def test_associations_filtered_by_with_retired
    assert_equal 2, @paranoid_forest_1.paranoid_trees.with_retired.count
    assert_equal 2, @paranoid_forest_2.paranoid_trees.with_retired.count

    @paranoid_forest_1.paranoid_trees.first.destroy

    assert_equal 1, @paranoid_forest_1.paranoid_trees.count
    assert_equal 2, @paranoid_forest_1.paranoid_trees.with_retired.count
    assert_equal 4, ParanoidTree.with_retired.count

    @paranoid_forest_2.paranoid_trees.first.destroy

    assert_equal 1, @paranoid_forest_2.paranoid_trees.count
    assert_equal 2, @paranoid_forest_2.paranoid_trees.with_retired.count
    assert_equal 4, ParanoidTree.with_retired.count

    @paranoid_forest_1.paranoid_trees.first.destroy

    assert_equal 0, @paranoid_forest_1.paranoid_trees.count
    assert_equal 2, @paranoid_forest_1.paranoid_trees.with_retired.count
    assert_equal 4, ParanoidTree.with_retired.count
  end

  def test_associations_filtered_by_only_deleted
    assert_equal 0, @paranoid_forest_1.paranoid_trees.only_retired.count
    assert_equal 0, @paranoid_forest_2.paranoid_trees.only_retired.count

    @paranoid_forest_1.paranoid_trees.first.destroy

    assert_equal 1, @paranoid_forest_1.paranoid_trees.only_retired.count
    assert_equal 1, ParanoidTree.only_retired.count

    @paranoid_forest_2.paranoid_trees.first.destroy

    assert_equal 1, @paranoid_forest_2.paranoid_trees.only_retired.count
    assert_equal 2, ParanoidTree.only_retired.count

    @paranoid_forest_1.paranoid_trees.first.destroy

    assert_equal 2, @paranoid_forest_1.paranoid_trees.only_retired.count
    assert_equal 3, ParanoidTree.only_retired.count
  end

  def test_fake_removal_through_relation
    # destroy: through a relation.
    ParanoidForest.rainforest.destroy(@paranoid_forest_3.id)

    assert_equal 1, ParanoidForest.rainforest.count
    assert_equal 2, ParanoidForest.rainforest.with_retired.count
    assert_equal 1, ParanoidForest.rainforest.only_retired.count

    # destroy_all: through a relation
    @paranoid_forest_2.paranoid_trees.destroy_all

    assert_equal 0, @paranoid_forest_2.paranoid_trees.count
    assert_equal 2, @paranoid_forest_2.paranoid_trees.with_retired.count
  end

  def test_fake_removal_through_has_many_relation_of_non_paranoid_model
    not_paranoid = NotParanoidBowl.create! name: "NotParanoid #1"
    not_paranoid.paranoid_chocolates.create! name: "ParanoidChocolate #1"
    not_paranoid.paranoid_chocolates.create! name: "ParanoidChocolate #2"

    not_paranoid.paranoid_chocolates.destroy_all

    assert_equal 0, not_paranoid.paranoid_chocolates.count
    assert_equal 2, not_paranoid.paranoid_chocolates.with_retired.count
  end

  def test_real_removal_through_relation_with_destroy_fully
    ParanoidForest.rainforest.destroy_fully!(@paranoid_forest_3)

    assert_equal 1, ParanoidForest.rainforest.count
    assert_equal 1, ParanoidForest.rainforest.with_retired.count
    assert_equal 0, ParanoidForest.rainforest.only_retired.count
  end

  def test_two_step_real_removal_through_relation_with_destroy
    # destroy: two-step through a relation
    paranoid_tree = @paranoid_forest_1.paranoid_trees.first
    @paranoid_forest_1.paranoid_trees.destroy(paranoid_tree.id)
    @paranoid_forest_1.paranoid_trees.only_retired.destroy(paranoid_tree.id)

    assert_equal 1, @paranoid_forest_1.paranoid_trees.count
    assert_equal 1, @paranoid_forest_1.paranoid_trees.with_retired.count
    assert_equal 0, @paranoid_forest_1.paranoid_trees.only_retired.count
  end

  def test_two_step_real_removal_through_relation_with_destroy_all
    # destroy_all: two-step through a relation
    @paranoid_forest_1.paranoid_trees.destroy_all
    @paranoid_forest_1.paranoid_trees.only_retired.destroy_all

    assert_equal 0, @paranoid_forest_1.paranoid_trees.count
    assert_equal 0, @paranoid_forest_1.paranoid_trees.with_retired.count
    assert_equal 0, @paranoid_forest_1.paranoid_trees.only_retired.count
  end

  def test_real_removal_through_relation_with_delete_all_bang
    # retire_all!: through a relation
    @paranoid_forest_2.paranoid_trees.retire_all!

    assert_equal 0, @paranoid_forest_2.paranoid_trees.count
    assert_equal 0, @paranoid_forest_2.paranoid_trees.with_retired.count
    assert_equal 0, @paranoid_forest_2.paranoid_trees.only_retired.count
  end
end
