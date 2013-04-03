require 'rubygems'
require 'nokogiri'
require 'fileutils'
require 'date'
require 'uri'
require 'find'

@posts = {}
@drafts = {}

# usage: ruby import.rb {path}
# {path} is the full path to your cloned github pages master branch

blog_path = ARGV[0]

def add(node)
  id = node.search('id').first.content
  type = node.search('category').first.attr('term').split('#').last
  @posts[id] = Post.new(node)
end

def write(post, path='_posts')
 
  puts "writing #{post.file_name}"
  File.open(File.join(path, post.file_name), 'w') do |file|
    file.write post.header
    file.write "\n\n"
    #file.write "<h1>{{ page.title }}</h1>\n"
    file.write "<div class='post'>\n"
    file.write post.content
    file.write "</div>\n"
  end
end

class Post
  def initialize(node)
    @node = node
  end
 
  def title
    @title ||= @node.at_css('.entry-title').content
  end
 
  def content
    @content ||= @node.search('.entry-content').inner_html
  end
 
  def creation_date
    @creation_date ||= creation_datetime.strftime("%Y-%m-%d")
  end
 
  def creation_datetime
    @creation_datetime ||= DateTime.parse(@node.search('time').first.attr('datetime'))
  end
 
  def permalink
    return @permalink unless @permalink.nil?
 
    link_node = @node.search('link[rel="canonical"]')
    @permalink = link_node.attr('href')
  end
 
  def param_name
    if permalink.nil?
      title.split(/[^a-zA-Z0-9]+/).join('-').downcase
    else
      File.basename(URI(permalink).path, '.*')
    end
  end
 
  def file_name
    %{#{creation_date}-#{param_name}.html}
  end
 
  def header
    [
      '---',
      %{layout: post},
      %{title: "#{escaped title}"},
      %{date: #{creation_datetime}},
      'comments: true',
      categories,
      '---'
    ].compact.join("\n")
  end
  
  def escaped(str)
    str.gsub('"') { '\"' }
  end
  
  def categories
    terms = @node.search('.categories a')
    unless Array(terms).empty?
      [
        'categories:',
        terms.map{ |t| t.content && " - #{t.content}" }.compact.join("\n"),
      ].join("\n")
    end
  end

end

Dir.foreach(blog_path) do |item|
  if item.to_i.to_s != "0"
    path = File.join(blog_path, item)
    Find.find(path) do |f|
      if f.match(/\index.html\Z/)
        data = File.read f
        doc = Nokogiri::XML(data)
        @posts[f] = Post.new(doc)
      end
    end
  end
end

puts "** Writing posts"
FileUtils.rm_rf('_posts')
Dir.mkdir("_posts") unless File.directory?("_posts")

@posts.each do |id, post|
  write post
end