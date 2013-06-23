require File.dirname(__FILE__) + '/../test_helper'
require 'fileutils'

class GroupTest < ActiveSupport::TestCase
  fixtures :all

  context "A Group" do
    should "be able to find all groups for listing in the app" do
      groups = Group.find_for_list
      assert_equal(2, groups.size)
      assert_equal(groups(:group_1), groups[0])
      assert_equal(groups(:group_2), groups[1])
    end

    should "be able to create mailing lables for group members" do
      group = groups(:group_1)
      group.addresses << [addresses(:chicago), addresses(:tinley_park), addresses(:alsip)]
      group.save

      labels = group.create_labels('Avery8660')
      assert_not_nil labels
    end

    should "be able to find all addresses eligible for group membership, but not in the group" do
      group = groups(:group_1)
      group.addresses = [addresses(:alsip)]
      group.save

      not_included = group.addresses_not_included
      assert_equal 2, not_included.size
      assert not_included.include?(addresses(:chicago))
      assert not_included.include?(addresses(:tinley_park))
    end

    should "be able to find all addresses eligible for group membership for a group with no current members" do
      group = groups(:group_1)

      not_included = group.addresses_not_included
      assert_equal 3, not_included.size
      assert not_included.include?(addresses(:chicago))
      assert not_included.include?(addresses(:tinley_park))
      assert not_included.include?(addresses(:alsip))
    end
  end

end
