module Locomotive
  module Import
    class Assets < Base

      def process
        self.add_theme_assets

        self.add_other_assets
      end

      protected
      
      def add_theme_assets
        Dir[File.join(File.join(theme_path, 'public'), '**/*')].each do |asset_path|
          next if File.directory?(asset_path)
          
          filename = File.basename(asset_path)
          folder = asset_path.gsub(File.join(theme_path, 'public'), '').gsub(File.basename(asset_path), '').gsub(/^\//, '').gsub(/\/$/, '')
          ac = site.asset_collections.where(:slug => folder).first || site.asset_collections.create!(:slug => folder, :name => folder)
          asset = ac.assets.where(:source_filename => filename).first || ac.assets.build
          asset.attributes = { :source => File.open(asset_path), :performing_plain_text => false, :name => filename }
          
          begin
            asset.save!
          rescue Exception => e
            self.log "!ERROR! = #{e.message}, #{asset_path}"
          end
            
          site.reload
        end
      end
      
      def add_other_assets
        Dir[File.join(theme_path, 'public', 'samples', '*')].each do |asset_path|

          next if File.directory?(asset_path)

          self.log "other asset = #{asset_path}"

          asset = site.assets.where(:source_filename => File.basename(asset_path)).first

          asset ||= self.site.assets.build

          asset.attributes = { :source => File.open(asset_path) }

          begin
            asset.save!
          rescue Exception => e
            self.log "!ERROR! = #{e.message}, #{asset_path}"
          end
        end
      end

    end
  end
end