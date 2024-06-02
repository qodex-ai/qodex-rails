module QodexRails
  class Configuration
    attr_accessor :collection_name, :api_key, :allowed_environments,
      :frequency, :api_host, :pii_masking

    def initialize
      @collection_name = nil
      @api_key = nil
      @allowed_environments = ['staging']
      @frequency = 'medium'
      @api_host = nil
      @pii_masking = nil
    end
  end
end
