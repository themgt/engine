class SearchablePage
  include Locomotive::Mongoid::Document
  
  field :fullpath
  field :title
  field :content
  
  ## associations ##
  referenced_in :site
  referenced_in :page
  
  ## validations ##
  validates_presence_of     :content, :fullpath, :title, :site
  validates_uniqueness_of   :fullpath, :scope => :site_id
  
  class << self
    def rebuild_page_index(site = nil)
      (site ? site.pages : Page.all).each do |page|
        if page.templatized?
          model_name = page.content_type.slug.singularize
          
          page.content_type.contents.map do |c|
            content_assigns = { 'content_instance' => c, model_name => c }
            sync_page_to_index(page, content_assigns)
          end
        else
          sync_page_to_index(page)
        end
      end
    end
    
    def sync_page_to_index(page, extra_assigns = {})
      site = page.site
      
      assigns = {
        'site'              => site,
        'page'              => page,
        'contents'          => Locomotive::Liquid::Drops::Contents.new,
        'current_page'      => nil,
        'params'            => {},
        'url'               => '/',
        'now'               => Time.now.utc,
        'today'             => Date.today,
      }

      registers = {
        :controller         => nil,
        :site               => site,
        :page               => page,
        :inline_editor      => false,
        :current_admin      => false,
        :disable_snippets   => true,
      }
      
      locomotive_context = ::Liquid::Context.new({}, assigns.merge(extra_assigns), registers)
      output    = page.render_text(locomotive_context)
      
      if ci = extra_assigns['content_instance']
        fullpath  = page.fullpath.sub('content_type_template', ci._slug)
        title     = ci.highlighted_field_value
      else
        fullpath  = page.fullpath
        title     = page.title
      end
      
      cached_page = site.searchable_pages.where(:fullpath => fullpath).first || site.searchable_pages.build(:fullpath => fullpath)
      puts "updating search index for #{title} => #{site.domains.first}/#{fullpath}"
      cached_page.update_attributes!(:title => title, :content => output.to_s)
    end
  end
  
  def to_liquid
    { }.merge(self.attributes).stringify_keys
  end
end