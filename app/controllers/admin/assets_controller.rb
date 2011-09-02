module Admin
  class AssetsController < BaseController
    sections 'assets'

    include ActionView::Helpers::SanitizeHelper
    include ActionView::Helpers::TextHelper
    
    before_filter :set_collections_and_current_collection
    before_filter :sanitize_params, :only => [:create, :update]
    respond_to :json, :only => [:index, :create, :destroy, :update]

    def index
      index! do |response|
        response.json do
          render :json => { :assets => @assets.collect { |asset| asset_to_json(asset) } }
        end
      end
    end
    
    def edit
      resource.performing_plain_text = true if resource.stylesheet_or_javascript?
      edit!
    end
    
    def create
      @asset = current_site.assets.build(:name => params[:name], :source => params[:file])

      create! do |success, failure|
        success.json do
          render :json => asset_to_json(@asset)
        end
        failure.json do
          render :json => { :status => 'error' }
        end
      end
    rescue Exception => e
      render :json => { :status => 'error', :message => e.message }
    end
    
    # for drag & drop upload
    def import
      asset = @asset_collection.assets.where(:source_filename => params[:file].original_filename).first ||
              @asset_collection.assets.build
      asset.attributes = {:source => params[:file], :name => params[:file].original_filename}
      
      if asset.save
        render :json => {:success => true}
      else
        #logger.error "[Asset upload error]: #{asset.errors.inspect} | #{params.inspect}"
        render :json => {:success => false}
      end
    end
    
    protected
    
    def sanitize_params
      params[:asset] = { :source => params[:file] } if params[:file]

      performing_plain_text = params[:asset][:performing_plain_text]
      params[:asset].delete(:content_type) if performing_plain_text.blank? || performing_plain_text == 'false'
    end
    
    def begin_of_association_chain
      @asset_collection
    end

    def set_collections_and_current_collection
      @asset_collections = current_site.asset_collections.not_internal.order_by([[:name, :asc]])
      @asset_collection = current_site.asset_collections.find(params[:collection_id])
    end
    
    def collection
      if params[:image]
        @assets ||= begin_of_association_chain.assets.only_image
      else
        @assets ||= begin_of_association_chain.assets
      end
    end

    def asset_to_json(asset)
      {
        :status       => 'success',
        :filename     => asset.source_filename,
        :short_name   => truncate(asset.name, :length => 15),
        :extname      => truncate(asset.extname, :length => 3),
        :content_type => asset.content_type,
        :url          => asset.source.url,
        :vignette_url => asset.vignette_url,
        :destroy_url  => admin_asset_url(asset, :json)
      }
    end

  end
end
