module Extensions
  module Asset
    module Vignette

      def vignette_url
        max_size_url(80)
      end
      
      def preview_url
        max_size_url(400)
      end
      
      def max_size_url(max_width, max_height = nil)
        max_height ||= max_width
        
        if self.image?
          if self.width < max_width && self.height < max_height
            self.source.url
          else
            Locomotive::Dragonfly.resize_url(self.source, "#{max_width}x#{max_height}#")
          end
        end
      end
    end
  end
end