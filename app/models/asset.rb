class Asset

  include Mongoid::Document
  include Mongoid::Timestamps

  ## extensions ##
  include Extensions::Asset::Types
  include Extensions::Asset::Vignette

  ## fields ##
  field :content_type, :type => String
  field :width, :type => Integer
  field :height, :type => Integer
  field :size, :type => Integer
  field :position, :type => Integer, :default => 0
  mount_uploader :source, AssetUploader

  ## associations ##
  referenced_in :site
  referenced_in :asset_collection#, :class_name => 'AssetCollection', :inverse_of => :assets

  ## validations ##
  validates_presence_of :source
  validates_uniqueness_of :source_filename, :scope => :asset_collection_id
  
  ## behaviours ##
  before_validation :store_plain_text

  ## methods ##
  attr_accessor :plain_text_name, :plain_text, :performing_plain_text

  alias :name :source_filename
  
  %w{image stylesheet javascript pdf media sass}.each do |type|
    define_method("#{type}?") do
      self.content_type.to_s == type
    end
  end
  
  def stylesheet_or_javascript?
    self.stylesheet? || self.javascript?
  end
  
  def performing_plain_text?
    Boolean.set(self.performing_plain_text) || false
  end
  
  def site_id # needed by the uploader of custom fields
    self.collection.site_id
  end
  
  def plain_text
    if RUBY_VERSION =~ /1\.9/
      @plain_text ||= (self.source.read.force_encoding('UTF-8') rescue nil)
    else
      @plain_text ||= self.source.read
    end
  end
  
  def store_plain_text
    return unless performing_plain_text?
    data = self.performing_plain_text? ? self.plain_text : self.source.read

    return if !self.stylesheet_or_javascript? || data.blank?
    
    self.source = CarrierWave::SanitizedFile.new({
      :tempfile => StringIO.new(data),
      :filename => source_filename
    })
  end
  
  def extname
    return nil unless self.source?
    File.extname(self.source_filename).gsub(/^\./, '')
  end

  def to_liquid
    { :url => self.source.url }.merge(self.attributes).stringify_keys
  end

end