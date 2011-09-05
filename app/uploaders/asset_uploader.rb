class AssetUploader < CarrierWave::Uploader::Base

  include Locomotive::CarrierWave::Uploader::Asset

  def store_dir
    File.join(model.asset_collection.site_id.to_s, model.asset_collection.slug)
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

end
