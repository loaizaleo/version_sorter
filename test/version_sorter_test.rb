# encoding: utf-8
require 'test/unit'
require 'version_sorter'
require 'rubygems/version'

class VersionSorterTest < Test::Unit::TestCase
  def setup
    version_struct = Struct.new(:name)

    @version1 = version_struct.new("1.0")
    @version2 = version_struct.new("2.0")
    @version10 = version_struct.new("10.0")
  end

  def test_sorts_versions_correctly
    versions = %w(1.0.9 1.0.10 2.0 3.1.4.2 1.0.9a)
    sorted_versions = %w( 1.0.9a 1.0.9 1.0.10 2.0 3.1.4.2 )

    assert_equal sorted_versions, VersionSorter.sort(versions)
  end

  def test_sorts_versions_like_rubygems
    versions = %w(1.0.9.b 1.0.9 1.0.10 2.0 3.1.4.2 1.0.9a 2.0rc2 2.0-rc1)
    if (Gem.rubygems_version < Gem::Version.new('2.1.0')) 
      # Old versions of RubyGems cannot parse semver versions like `2.0-rc1`
      versions.pop()
    end
    sorted_versions = versions.sort_by { |v| Gem::Version.new(v) }

    assert_equal sorted_versions, VersionSorter.sort(versions)
  end

  def test_returns_same_object
    versions = %w( 2.0 1.0 0.5 )
    sorted = VersionSorter.sort(versions)

    assert_equal versions[2].object_id, sorted[0].object_id
  end

  def test_reverse_sorts_versions_correctly
    versions = %w(1.0.9 1.0.10 2.0 3.1.4.2 1.0.9a)
    sorted_versions = %w( 3.1.4.2 2.0 1.0.10 1.0.9 1.0.9a )

    assert_equal sorted_versions, VersionSorter.rsort(versions)
  end

  def test_does_not_raise_on_number_overflow
    big_numbers = [
      (2**32).to_s,
      (2**32 + 1).to_s,
      (2**32 + 2).to_s,
      (2**32 - 2).to_s,
      (2**32 - 1).to_s,
    ]
    randomized = shuffle big_numbers

    assert_equal big_numbers, VersionSorter.sort(randomized)
  end

  def test_handles_non_version_data
    non_versions = [
      "", " ", ".", "-", "ćevapčići", "The Quick Brown Fox", '!@#$%^&*()',
      "<--------->", "a12a8a4a22122d01541b62193e9bdad7f5eda552", "1." * 65
    ]
    sorted = [
      "<--------->", "-", "The Quick Brown Fox",
      "a12a8a4a22122d01541b62193e9bdad7f5eda552", "ćevapčići",
      "", " ", ".", '!@#$%^&*()', "1." * 65
    ]

    assert_equal sorted, VersionSorter.sort(non_versions)
  end

  def test_sort_bang
    versions = ["10.0", "1.0", "2.0"]
    VersionSorter.sort! versions
    assert_equal ["1.0", "2.0", "10.0"], versions
  end

  def test_rsort_bang
    versions = ["10.0", "1.0", "2.0"]
    VersionSorter.rsort! versions
    assert_equal ["10.0", "2.0", "1.0"], versions
  end

  def test_sort_block
    versions = [@version10, @version1, @version2]
    sorted = VersionSorter.sort(versions) { |version| version.name }
    assert_equal [@version1, @version2, @version10], sorted
  end

  def test_rsort_block
    versions = [@version10, @version1, @version2]
    sorted = VersionSorter.rsort(versions) { |version| version.name }
    assert_equal [@version10, @version2, @version1], sorted
  end

  def test_compare
    assert VersionSorter.compare("10.0", "1.0") > 0
    assert VersionSorter.compare("10.0", "12.0") < 0
    assert_equal 0, VersionSorter.compare("12.0", "12.0")
  end

  def shuffle(array)
    array, result = array.dup, []
    result << array.delete_at(rand(array.size)) until array.size.zero?
    result
  end
end
