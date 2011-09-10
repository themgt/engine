module Extensions
  module Page
    module Render
      extend ActiveSupport::Concern
      
      included do
        include ActionView::Helpers::SanitizeHelper
      end
      
      def render(context)
        self.template.render(context)
      end
      
      def render_text(context)
        strip_tags(render(context))
      end
    end
  end
end