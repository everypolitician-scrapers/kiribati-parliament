#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

class MembersList < Scraped::HTML
  field :members do
    noko.css('#content pre').map(&:text).each_slice(2).flat_map do |party, members|
      cleanparty = party.gsub(/\(.*?\)/, '').tidy
      members.lines.map { |line| fragment(line => MemberLine).to_h.merge(party: cleanparty) }
    end
  end
end

class MemberLine < Scraped::HTML
  field :id do
    name.downcase.tr(' ', '-')
  end

  field :name do
    name_parts.name
  end

  field :gender do
    name_parts.gender
  end

  field :honorific_prefix do
    name_parts.prefix
  end

  field :area do
    lineparts.last.split('-').first.tidy
  end

  private

  def lineparts
    noko.split(/  +/, 2)
  end

  def name_parts
    fragment lineparts.first.tidy => MemberName
  end
end

class MemberName < Scraped::HTML
  field :prefix do
    partitioned.first.join(' ')
  end

  field :name do
    partitioned.last.join(' ')
  end

  field :gender do
    return 'male' if (prefixes & MALE_PREFIXES).any?
    return 'female' if (prefixes & FEMALE_PREFIXES).any?
  end

  private

  FEMALE_PREFIXES  = %w[mrs miss ms].freeze
  MALE_PREFIXES    = %w[mr].freeze
  OTHER_PREFIXES   = %w[dr].freeze
  PREFIXES         = FEMALE_PREFIXES + MALE_PREFIXES + OTHER_PREFIXES

  def partitioned
    words.partition { |w| PREFIXES.include? w.chomp('.').downcase }
  end

  def prefixes
    partitioned.first.map { |w| w.downcase.chomp('.') }
  end

  def words
    noko.split(/\s+/)
  end
end

url = 'http://www.parliament.gov.ki/party-members/'
Scraped::Scraper.new(url => MembersList).store(:members)
