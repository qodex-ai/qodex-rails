module QodexRails
  class Configuration
    attr_accessor :collection_name, :api_key, :allowed_environments, :frequency

    def initialize
      @collection_name = nil
      @api_key = nil
      @allowed_environments = ['staging']
      @frequency = 'medium'
    end
  end
end
