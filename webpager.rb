require 'nokogiri'
require 'open-uri'

# page = Webpager.new('http://seanbehan.com')
# page.html
# page.text
# page.excerpt
class Webpager
  def initialize(url)
    @url = url
  end

  def html
    @html ||= open(@url.strip).read
  end

  def doc
    @doc ||= Nokogiri::HTML(html)
  end

  def text
    all_tags     = /<\/?[^>]+>/i
    ref_tags     = /<(a|img)(.*)>/i
    script_tags  = /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/i
    style_tags   = /<style\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/style>/i
    iframe_tags  = /<iframe\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/iframe>/i
    comment_tags = /<!--\b[^<]*(?:(?!<\/script>)<[^<]*)*-->/i

    regexp = Regexp.union(all_tags, script_tags, style_tags, iframe_tags, comment_tags)

    body
    .gsub(ref_tags) { |tag| ((links = URI.extract(tag)).any? ? links.join(' ') : '') }
    .gsub(regexp, '')
    .split("\n")
    .map(&:strip)
    .reject(&:blank?)
    .join("\n")
  end

  def body
    doc.xpath('//body').inner_html
  end

  def excerptable?(text='')
    text.split('.').size >= 2 && text.size > 100
  end

  def title
    html.match(/<title>(.*)<\/title>/) { $1 }
  end

  def favicon
    # doc.xpath('//link/').select { |link| link.value =~ /favi/ }
  end

  def excerpt
    (doc.xpath('//p').map do |x|
      excerptable?(x.content) ? x.content : nil
    end.compact.first||"").strip
  end
end
