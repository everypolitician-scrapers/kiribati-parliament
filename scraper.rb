#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('#content-inner ol').each do |ol|
    party = ol.xpath('preceding-sibling::p/strong').last.text.tidy
    puts party.to_s.cyan
    ol.css('li').each do |li|
      line = li.css('strong').count.zero? ? li.text.tidy : li.css('strong').text.tidy
      who, area, _ = line.split(/[\(\)]/)
      prefix, name = who.match(/^(H.E|Hon. Dr|Hon|[MD]r?|Mr?s?|Mr Mr)[\. ](.*)$/).captures
      data = { 
        # id: "%s-%s" % [who.downcase.gsub(/[[:space:]]+/,'-'), first_seen],
        name: name.sub('Attorney General','').tidy,
        prefix: prefix, 
        party: party,
        area: area.to_s.sub(/^MP /,'').tidy,
        gender: prefix.match(/Mr?s/) ? 'female' : prefix.include?('Mr') ? 'male' : '',
        term: 10,
        # source: url.to_s,
      }
      puts data
      # ScraperWiki.save_sqlite([:id, :term], data)
    end
  end
end

scrape_list('http://www.parliament.gov.ki/content/party-members')
