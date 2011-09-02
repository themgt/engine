# encoding: utf-8
class AssetUploader < CarrierWave::Uploader::Base

  include CarrierWave::RMagick
  delegate :created_at, :updated_at, :image?, :sass?, :to => :model
  
  def store_dir
    File.join(model.collection.site_id.to_s, model.collection.slug)
  end
  
  def cache_dir
    File.join(Rails.root, "tmp/uploads")
  end
  
  def local_dir
    File.join(Rails.root, "tmp/grifizoid", store_dir)
  end
  
  def current_path
    ensure_local_file_exists
    local_path
  end
  
  # TODO: fix confusing naming - cache dir is class-wide, cache_path is for this specific instance
  def local_path
    File.join(local_dir, model.source_filename || original_filename)
  end
  
  def ensure_local_file_exists
    cache_file_locally unless local_cache_current?
  end
  
  def local_cache_current?
    File.exists?(local_path) and 
      Digest::MD5.hexdigest(File.read(local_path)) == Digest::MD5.hexdigest(read)
  end
  
  def cache_file_locally
    FileUtils.mkdir_p(File.dirname(local_path))
    
    File.open(local_path, 'wb'){ |f| f << read }
  end

  process :set_content_type
  process :set_size
  process :set_width_and_height
  #process :ensure_local_file_exists
  process :compile_sass
  
  def set_content_type(*args)
    value = 'other'

    content_type = file.content_type == 'application/octet-stream' ? File.mime_type?(original_filename) : file.content_type
    
    self.class.content_types.each_pair do |type, rules|
      rules.each do |rule|
        case rule
        when String then value = type if content_type == rule
        when Regexp then value = type if (content_type =~ rule) == 0
        end
      end
    end
    
    # try to extract something from the filename
    value = (File.extname(original_filename).sub(/^\./, '').presence || 'other') if value == 'other'
    
    file.content_type = File.mime_type?(original_filename)
    model.content_type = value
  end

  def set_size(*args)
    model.size = file.size
  end

  def set_width_and_height
    if image?
      magick = ::Magick::Image.read(current_path).first
      model.width, model.height = magick.columns, magick.rows
    end
  end
  
  def compile_sass
    if sass?
      ensure_local_file_exists
      model.collection.compile(model)
    end
  end

  def self.content_types
    {
      :image      => ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png', 'image/jpg', 'image/x-icon'],
      :media      => [/^video/, 'application/x-shockwave-flash', 'application/x-swf', /^audio/, 'application/ogg', 'application/x-mp3'],
      :pdf        => ['application/pdf', 'application/x-pdf'],
      :stylesheet => ['text/css'],
      :javascript => ['text/javascript', 'text/js', 'application/x-javascript', 'application/javascript'],
      :font       => ['application/x-font-ttf', 'application/vnd.ms-fontobject', 'image/svg+xml', 'application/x-woff']
    }
  end

end
