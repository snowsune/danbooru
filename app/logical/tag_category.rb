# frozen_string_literal: true

# Utility methods for working with tag categories (general, character,
# copyright, artist, meta).

module TagCategory
  module_function

  GENERAL = 0
  ARTIST = 1
  COPYRIGHT = 3
  CHARACTER = 4
  META = 5
  SPECIES = 6
  TROPE = 7

  # Returns a hash mapping various tag categories to a numerical value.
  def mapping
    {
      "ch" => 4,
      "co" => 3,
      "gen" => 0,
      "char" => 4,
      "copy" => 3,
      "art" => 1,
      "meta" => 5,
      "species" => 6,
      "trope" => 7,
      "general" => 0,
      "character" => 4,
      "copyright" => 3,
      "artist" => 1,
    }
  end

  # The order of tags in dropdown lists.
  def canonical_mapping
    {
      "Artist"    => 1,
      "Copyright" => 3,
      "Species"   => 6,
      "Character" => 4,
      "General"   => 0,
      "Meta"      => 5,
      "Trope"     => 7,
    }
  end

  # Returns a hash mapping numerical category values to their string equivalent.
  def reverse_mapping
    {
      0 => "general",
      4 => "character",
      6 => "species",
      3 => "copyright",
      1 => "artist",
      5 => "meta",
      7 => "trope",
    }
  end

  def short_name_mapping
    {
      "art"     => "artist",
      "copy"    => "copyright",
      "char"    => "character",
      "gen"     => "general",
      "meta"    => "meta",
      "species" => "species",
      "trope"   => "trope",
    }
  end

  def categories
    %w[general character copyright artist meta species trope]
  end

  def category_ids
    canonical_mapping.values
  end

  def short_name_list
    %w[art copy char gen meta species trope]
  end

  # The order of tags on the post page tag list.
  def split_header_list
    %w[artist copyright character species general trope meta]
  end

  # The order of tags inside the tag edit box, and on the comments page.
  def categorized_list
    %w[artist copyright character species meta trope general]
  end

  # Which tag categories to show in the related tags box for a tag of the given type.
  def related_tag_categories
    @related_tag_categories ||= {
      GENERAL   => [GENERAL],
      ARTIST    => [COPYRIGHT, CHARACTER, GENERAL],
      CHARACTER => [COPYRIGHT, CHARACTER, GENERAL, SPECIES],
      COPYRIGHT => [COPYRIGHT, CHARACTER, GENERAL],
      META      => [META, GENERAL, TROPE],
      SPECIES   => [CHARACTER, GENERAL],
      TROPE     => [META, GENERAL],
    }
  end

  # Which tag categories to show in the sidebar tag list when searching for a tag.
  def search_sidebar_tag_categories
    @search_sidebar_tag_categories ||= {
      GENERAL   => [COPYRIGHT, CHARACTER, GENERAL, META],
      ARTIST    => [COPYRIGHT, CHARACTER, GENERAL, META],
      CHARACTER => [COPYRIGHT, CHARACTER, GENERAL, META],
      COPYRIGHT => [COPYRIGHT, CHARACTER, GENERAL, META],
      META      => [COPYRIGHT, CHARACTER, META, GENERAL],
      SPECIES   => [CHARACTER, GENERAL],
      TROPE     => [META, GENERAL],
    }
  end

  def category_ids_regex
    "[#{category_ids.join}]"
  end
end
