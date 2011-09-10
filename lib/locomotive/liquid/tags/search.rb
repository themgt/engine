module Locomotive
  module Liquid
      module Tags
      # Search page index for a query param
      #
      # Usage:
      #
      # {% search params.q %}
      #   {% for result in results %}
      #     {{ result.title }}
      #   {% endfor %}
      # {% endsearch %}
      #
      class Search < ::Liquid::Block

        Syntax = /(#{::Liquid::Expression}+)/

        def initialize(tag_name, markup, tokens, context)
          if markup =~ Syntax
            @query_str = $1
            @options = {}
            markup.scan(::Liquid::TagAttributes) do |key, value|
              @options[key] = value
            end
          else
            raise ::Liquid::SyntaxError.new("Syntax Error in 'search'")
          end

          super
        end

        def render(context)
          context.stack do
            query = context[@query_str]
            context.scopes.last['results'] = context.registers[:site].searchable_pages.where(:content => /#{query}/i).limit(10)
            
            render_all(@nodelist, context)
          end
        end
      end

      ::Liquid::Template.register_tag('search', Search)
    end
  end
end
